package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Carp 'croak';

our @EXPORT_OK = qw(
    implicit_step
    list_paths
    path
    path_delta
);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path"><img src="https://badge.fury.io/pl/Struct-Path.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.84

=cut

our $VERSION = '0.84';

=head1 SYNOPSIS

    use Struct::Path qw(list_paths path);

    $s = [
        0,
        {
            two => {
                three => 3,
                four => 4
            }
        },
        undef
    ];

    @list = list_paths($s);                         # list paths and values
    # @list == (
    #   [[0]], \0,
    #   [[1],{K => ['two']},{K => ['four']}], \4,
    #   [[1],{K => ['two']},{K => ['three']}], \3,
    #   [[2]], \undef
    # )

    @r = path($s, [ [1],{K => ['two']} ]);         # get refs to values
    # @r == (\{four => 4,three => 3})

=head1 DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data
structures.

Why L<existed modules|/"SEE ALSO"> are not enough? This module has no
conflicts for paths like '/a/0/c', where C<0> may be an array index or a key
for hash (depends on passed structure). This is vital in some cases, for
example, when one need to define exact path in structure, but unable to
validate it's schema or when structure itself doesn't yet exist (see
option C<expand> for L</path>).

=head1 EXPORT

Nothing is exported by default.

=head1 ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in the structure.

Arrayref as a step stands for ARRAY and must contain desired items indexes or
be empty (means "all items"). Sequence for indexes define result sequence.

Hashref represent HASH and may contain key C<K> or be empty. C<K>'s value
should be a list of desired keys and compiled regular expressions. Empty
hash or empty list for C<K> means all keys, sequence in the list define
resulting sequence.

Coderef step is a hook - subroutine which may filter out items and/or modify
structure. Traversed path for first, stack of passed structured for secong and
path remainder for third agrument passed to hook when executed; all passed args
are arrayrefs. Among this two global variables available within hook: C<$_> is
set to current substructure and C<$_{opts}> contains c<path()>'s options. Some
true (match) value or false (doesn't match) value expected as output.

Sample:

    $path = [
        [1,7],                      # first spep
        {K => [qr/foo/,qr/bar/]}    # second step
        sub { exists $_->{bar} }    # third step
    ];

Struct::Path designed to be machine-friendly. See L<Struct::Path::PerlStyle>
and L<Struct::Path::JsonPointer> for human friendly path definition.

=head1 SUBROUTINES

=head2 implicit_step

    $bool = implicit_step($step);

Returns true value if step contains hooks or specified 'all' items or regexp
match.

=cut

sub implicit_step {
    if (ref $_[0] eq 'ARRAY') {
        return 1 unless (@{$_[0]});
    } elsif (ref $_[0] eq 'HASH') {
        return 1 unless (exists $_[0]->{K});
        return 1 unless (@{$_[0]->{K}});
        ref $_ eq 'Regexp' && return 1 for (@{$_[0]->{K}})
    } else { # hooks
        return 1;
    }

    return undef;
}

=head2 list_paths

Returns list of paths and references to their values from structure.

    @list = list_paths($structure, %opts)

=head3 Options

=over 4

=item depth C<< <N> >>

Don't dive into structure deeper than defined level.

=back

=cut

sub list_paths($;@) {
    my @stack = ([], \shift); # init: (path, ref)
    my %opts = @_;

    my (@out, $path, $ref);
    my $depth = defined $opts{depth} ? $opts{depth} : -1;

    while (($path, $ref) = splice @stack, 0, 2) {
        if (ref ${$ref} eq 'HASH' and @{$path} != $depth and keys %{${$ref}}) {
            map { unshift @stack, [@{$path}, {K => [$_]}], \${$ref}->{$_} }
                reverse sort keys %{${$ref}};
        } elsif (ref ${$ref} eq 'ARRAY' and @{$path} != $depth and @{${$ref}}) {
            map { unshift @stack, [@{$path}, [$_]], \${$ref}->[$_] }
                reverse 0 .. $#{${$ref}}
        } else {
            push @out, $path, $ref;
        }
    }

    return @out;
}

=head2 path

Returns list of references from structure.

    @found = path($structure, $path, %opts)

=head3 Options

=over 4

=item assign C<< <value> >>

Assign provided value to substructures pointed by path.

=item delete C<< <true|false> >>

Delete specified by path items from structure.

=item deref C<< <true|false> >>

Dereference result items.

=item expand C<< <true|false> >>

Expand structure if specified in path items doesn't exist. All newly created
items initialized by C<undef>.

=item paths C<< <true|false> >>

Return path for each result.

=item stack C<< <true|false> >>

Return stack of references to substructures.

=item strict C<< <true|false> >>

Croak if at least one element, specified by path, absent in the structure.

=back

All options are disabled (C<undef>) by default.

=cut

sub path($$;@) {
    my (undef, $init_path, %opts) = @_;

    croak "Arrayref expected for path" unless (ref $init_path eq 'ARRAY');
    croak "Unable to remove passed thing entirely (empty path passed)"
        if ($opts{delete} and not @{$init_path});

    # use alias for refs - to be able to rewrite passed scalar
    my @stack = ([], [\$_[0]], [@{$_[1]}]);
    my (@done, $items, $path, $pos, $refs, $rest, $step, $step_type);

    while (($path, $refs, $rest) = splice @stack, 0, 3) {
        if (not ref $refs->[-1]) {
            croak "Reference expected for refs stack entry, step #$pos";
        } elsif (not @{$rest}) {
            ${$refs->[-1]} = $opts{assign} if (exists $opts{assign});

            if ($opts{stack}) {
                map { $_ = ${$_} } @{$refs} if ($opts{deref});
            } else {
                $refs = $opts{deref} ? ${$refs->[-1]} : $refs->[-1];
            }

            push @done, ($opts{paths} ? ($path, $refs) : $refs);

            next;
        }

        $step = shift @{$rest};
        $pos = $#{$init_path} - @{$rest};

        if (($step_type = ref $step) eq 'HASH') {
            if (ref ${$refs->[-1]} ne 'HASH') {
                croak "HASH expected on step #$pos, got " . ref ${$refs->[-1]}
                    if ($opts{strict});
                next unless ($opts{expand});
                ${$refs->[-1]} = {};
            }

            undef $items;

            if (exists $step->{K}) {
                croak "Unsupported HASH definition, step #$pos"
                    if (keys %{$step} > 1);
                croak "Unsupported HASH keys definition, step #$pos"
                    unless (ref $step->{K} eq 'ARRAY');

                for my $i (@{$step->{K}}) {
                    if (ref $i eq 'Regexp') {
                        push @{$items}, grep { /$i/ } keys %{${$refs->[-1]}};
                    } else {
                        unless ($opts{expand} or exists ${$refs->[-1]}->{$i}) {
                            croak "{$i} doesn't exist, step #$pos"
                                if $opts{strict};
                            next;
                        }
                        push @{$items}, $i;
                    }
                }
            } else {
                croak "Unsupported HASH definition, step #$pos"
                    if (keys %{$step});
            }

            for (exists $step->{K} ? @{$items} : keys %{${$refs->[-1]}}) {
                push @stack,
                    [@{$path}, {K => [$_]}],
                    [@{$refs}, \${$refs->[-1]}->{$_}],
                    [@{$rest}];

                delete ${$refs->[-1]}->{$_}
                    if ($opts{delete} and not @{$rest});
            }
        } elsif ($step_type eq 'ARRAY') {
            if (ref ${$refs->[-1]} ne 'ARRAY') {
                croak "ARRAY expected on step #$pos, got " . ref ${$refs->[-1]}
                    if ($opts{strict});
                next unless ($opts{expand});
                ${$refs->[-1]} = [];
            }

            $items = @{$step} ? $step : [0 .. $#${$refs->[-1]}];
            for (@{$items}) {
                unless (
                    $opts{expand} or
                    @{${$refs->[-1]}} > ($_ >= 0 ? $_ : abs($_ + 1))
                ) {
                    croak "[$_] doesn't exist, step #$pos" if ($opts{strict});
                    next;
                }

                if ($_ < 0) {
                    if (@{${$refs->[-1]}} < abs($_)) {
                        # expand smoothly for out of range negative indexes
                        $_ = @{${$refs->[-1]}};
                    } else {
                        $_ += @{${$refs->[-1]}};
                    }
                }

                push @stack,
                    [@{$path}, [$_]],
                    [@{$refs}, \${$refs->[-1]}->[$_]],
                    [@{$rest}];
            }

            if ($opts{delete} and not @{$rest}) {
                for (reverse sort @{$items}) {
                    splice(@{${$refs->[-1]}}, $_, 1)
                        if ($_ < @{${$refs->[-1]}});
                }
            }
        } elsif ($step_type eq 'CODE') {
            local $_ = ${$refs->[-1]};
            local $_{opts} = \%opts;

            $step->($path, $refs, $rest) and
                push @stack, $path, $refs, [@{$rest}];
        } else {
            croak "Unsupported thing in the path, step #$pos";
        }
    }

    return @done;
}

=head2 path_delta

Returns delta for two passed paths. By delta means list of steps from the
second path without beginning common steps for both.

    @delta = path_delta($path1, $path2)

=cut

sub path_delta($$) {
    my ($frst, $scnd) = @_;

    croak "Second path must be an arrayref" unless (ref $scnd eq 'ARRAY');
    return @{$scnd} unless (defined $frst);
    croak "First path may be undef or an arrayref" unless (ref $frst eq 'ARRAY');

    require B::Deparse;
    my $deparse = B::Deparse->new();
    my $i = 0;

    MAIN:
    while ($i < @{$frst} and ref $frst->[$i] eq ref $scnd->[$i]) {
        if (ref $frst->[$i] eq 'ARRAY') {
            last unless (@{$frst->[$i]} == @{$scnd->[$i]});
            for (0 .. $#{$frst->[$i]}) {
                last MAIN unless ($frst->[$i]->[$_] == $scnd->[$i]->[$_]);
            }
        } elsif (ref $frst->[$i] eq 'HASH') {
            last unless (@{$frst->[$i]->{K}} == @{$scnd->[$i]->{K}});
            for (0 .. $#{$frst->[$i]->{K}}) {
                last MAIN unless (
                    $frst->[$i]->{K}->[$_] eq
                    $scnd->[$i]->{K}->[$_]
                );
            }
        } elsif (ref $frst->[$i] eq 'CODE') {
            last unless (
                $deparse->coderef2text($frst->[$i]) eq
                $deparse->coderef2text($scnd->[$i])
            );
        } else {
            croak "Unsupported thing in the path, step #$i";
        }

        $i++;
    }

    return @{$scnd}[$i .. $#{$scnd}];
}

=head1 LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path/>

=back

=head1 SEE ALSO

L<Data::Diver> L<Data::DPath> L<Data::DRef> L<Data::Focus> L<Data::Hierarchy>
L<Data::Nested> L<Data::PathSimple> L<Data::Reach> L<Data::Spath> L<JSON::Path>
L<MarpaX::xPathLike> L<Sereal::Path> L<Data::Find>

L<Struct::Diff> L<Struct::Path::PerlStyle> L<Struct::Path::JsonPointer>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2019 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
