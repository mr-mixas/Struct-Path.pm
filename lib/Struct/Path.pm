package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);

our @EXPORT_OK = qw(
    is_implicit_step
    slist
    spath
    spath_delta
);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=head1 VERSION

Version 0.70

=cut

our $VERSION = '0.70';

=head1 SYNOPSIS

    use Struct::Path qw(slist spath spath_delta);

    $s = [
        0,
        1,
        {
            '2a' => {
                '2aa' => '2aav',
                '2ab' => '2abv'
            }
        },
        undef
    ];

    @list = slist($s);                              # get paths and refs to values
    # @list == (
    #     [[0]], \0,
    #     [[1]], \1,
    #     [[2],{keys => ['2a']},{keys => ['2aa']}], \'2aav',
    #     [[2],{keys => ['2a']},{keys => ['2ab']}], \'2abv',
    #     [[3]], \undef
    # )

    @r = spath($s, [ [3,0,1] ]);                    # get refs to values by paths
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{keys => ['2a']},{} ]);    # same, another example
    # @r == (\'2aav', \'2abv')

    @r = spath($s, [ [2],{},{regs => [qr/^2a/]} ]); # or using regular expressions
    # @r == (\'2aav', \'2abv')

    ${$r[0]} =~ s/2a/blah-blah-/;                   # replace substructire by path
    # $s->[2]{2a}{2aa} eq "blah-blah-av"

    @d = spath_delta([[0],[4],[2]], [[0],[1],[3]]); # new steps relatively for first path
    # @d == ([1],[3])

=head1 DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data structures.

Why existed *Path* modules (L</"SEE ALSO">) is not enough? Used scheme has no collisions
for paths like '/a/0/c' ('0' may be an ARRAY index or a key for HASH, depends on passed
structure). In some cases this is important, for example, when you want to define exact
path in structure, but unable to validate it's schema or when structure doesn't exists
yet (see L</expand> for example).

=head1 EXPORT

Nothing is exported by default.

=head1 ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in structure.

Arrayref as a step stands for ARRAY in structure and must contain desired indexes or be
empty (means "all items"). Sequence for indexes is important and defines result sequence.

Hashref represents HASH in the structure and may contain keys C<keys>, C<regs> or be
empty. C<keys> may contain list of desired keys, C<regs> must contain list of regular
expressions. Empty hash or empty list for C<keys> means all keys. Sequence in C<keys>
and C<regs> lists defines result sequence. C<keys> have higher priority than C<regs>.

Sample:

    $spath = [
        [1,7],
        {regs => qr/foo/}
    ];

Since v0.50 coderefs (filters) as steps supported as well. Path as first argument and stack
of references (arrayref) as second passed to it when executed. Some true (match) value or
false (doesn't match) value expected as output.

See L<Struct::Path::PerlStyle> if you're looking for human friendly path definition method.

=head1 SUBROUTINES

=head2 is_implicit_step

    $implicit = is_implicit_step($step);

Returns true value if step contains filter or specified all keys/items or key regexp match.

=cut

sub is_implicit_step {

    if (ref $_[0] eq 'ARRAY') {
        return 1 unless (@{$_[0]});
    } elsif (ref $_[0] eq 'HASH') {
        return 1 if (exists $_[0]->{regs} and @{$_[0]->{regs}});
        return 1 unless (exists $_[0]->{keys});
        return 1 unless (@{$_[0]->{keys}});
    } else { # coderefs
        return 1;
    }

    return undef;
}

=head2 slist

Returns list of paths and references to their values from structure.

    @list = slist($struct, %opts)

=head3 Available options

=over 4

=item depth C<< <N> >>

Don't dive into structure deeper than defined level.

=back

=cut

sub slist($;@) {
    my @stack = ([], \shift); # init: (path, ref)
    my %opts = @_;

    my (@out, $path, $ref);
    my $depth = defined $opts{depth} ? $opts{depth} : -1;

    while (@stack) {
        ($path, $ref) = splice @stack, 0, 2;

        if (ref ${$ref} eq 'HASH' and @{$path} != $depth and keys %{${$ref}}) {
            map { unshift @stack, [@{$path}, {keys => [$_]}], \${$ref}->{$_} }
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

=head2 spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

=head3 Available options

=over 4

=item delete C<< <true|false> >>

Delete specified by path items from structure.

=item deref C<< <true|false> >>

Dereference result items.

=item expand C<< <true|false> >>

Expand structure if specified in path items does't exists. All newly created items initialized by C<undef>.

=item strict C<< <true|false> >>

Croak if at least one element, specified in path, absent in the struct.

=back

=cut

sub spath($$;@) {
    my ($struct, $spath, %opts) = @_;

    croak "Reference expected for structure" unless (ref $struct);
    croak "Path must be arrayref" unless (ref $spath eq 'ARRAY');

    my @out = ([], [ref $struct eq 'SCALAR' ? $struct : \$struct]);
    my $sc = 0; # step counter
    my ($items, @next, $path, $refs, @types);

    for my $step (@{$spath}) {
        while (@out) {
            ($path, $refs) = splice @out, 0, 2;

            if (ref $step eq 'ARRAY') {
                if (ref ${$refs->[-1]} ne 'ARRAY') {
                    croak "ARRAY expected on step #$sc, got " . ref ${$refs->[-1]}
                        if ($opts{strict});
                    next unless ($opts{expand});
                    ${$refs->[-1]} = [];
                }

                $items = @{$step} ? $step : [0 .. $#${$refs->[-1]}];
                for (@{$items}) {
                    unless ($opts{expand} or @{${$refs->[-1]}} > $_) {
                        croak "[$_] doesn't exists (step #$sc)" if ($opts{strict});
                        next;
                    }
                    push @next, [@{$path}, [$_]], [@{$refs}, \${$refs->[-1]}->[$_]];
                }

                if ($opts{delete} and $sc == $#{$spath}) {
                    map { splice(@{${$refs->[-1]}}, $_, 1) if ($_ <= $#{${$refs->[-1]}}) }
                        reverse sort @{$items};
                }
            } elsif (ref $step eq 'HASH') {
                if (ref ${$refs->[-1]} ne 'HASH') {
                    croak "HASH expected on step #$sc, got " . ref ${$refs->[-1]}
                        if ($opts{strict});
                    next unless ($opts{expand});
                    ${$refs->[-1]} = {};
                }

                @types = grep { exists $step->{$_} } qw(keys regs);
                croak "Unsupported HASH definition (step #$sc)" if (@types != keys %{$step});
                undef $items;

                for my $t (@types) {
                    croak "Unsupported HASH $t definition (step #$sc)"
                        unless (ref $step->{$t} eq 'ARRAY');

                    if ($t eq 'keys') {
                        for (@{$step->{keys}}) {
                            unless ($opts{expand} or exists ${$refs->[-1]}->{$_}) {
                                croak "{$_} doesn't exists (step #$sc)" if $opts{strict};
                                next;
                            }
                            push @{$items}, $_;
                        }
                    } else {
                        for my $g (@{$step->{regs}}) {
                            push @{$items}, grep { $_ =~ $g } keys %{${$refs->[-1]}};
                        }
                    }
                }

                for (@types ? @{$items} : keys %{${$refs->[-1]}}) {
                    push @next, [@{$path}, {keys => [$_]}], [@{$refs}, \${$refs->[-1]}->{$_}];
                    delete ${$refs->[-1]}->{$_} if ($opts{delete} and $sc == $#{$spath});
                }
            } elsif (ref $step eq 'CODE') {
                $step->($path, $refs) and push @next, $path, $refs;
            } else {
                croak "Unsupported thing in the path (step #$sc)";
            }
        }

        @out = splice @next;
        $sc++;
    }

    my @result;
    while (@out) {
        ($path, $refs) = splice @out, 0, 2;
        $refs = $opts{deref} ? ${pop @{$refs}} : pop @{$refs};
        push @result, ($opts{paths} ? [$path, $refs] : $refs);
    }

    return @result;
}

=head2 spath_delta

Returns delta for two passed paths. By delta means steps from the second path without beginning common steps for both.

    @delta = spath_delta($path1, $path2)

=cut

sub spath_delta($$) {
    my ($frst, $scnd) = @_;

    croak "Second path must be an arrayref" unless (ref $scnd eq 'ARRAY');
    return @{$scnd} unless (defined $frst);
    croak "First path may be undef or an arrayref" unless (ref $frst eq 'ARRAY');

    my $i = 0;

    MAIN:
    while ($i < @{$frst}) {
        last unless (ref $frst->[$i] eq ref $scnd->[$i]);
        if (ref $frst->[$i] eq 'ARRAY') {
            last unless (@{$frst->[$i]} == @{$scnd->[$i]});
            for my $j (0 .. $#{$frst->[$i]}) {
                last MAIN unless ($frst->[$i]->[$j] == $scnd->[$i]->[$j]);
            }
        } elsif (ref $frst->[$i] eq 'HASH') {
            last unless (@{$frst->[$i]->{keys}} == @{$scnd->[$i]->{keys}});
            for my $j (0 .. $#{$frst->[$i]->{keys}}) {
                last MAIN unless ($frst->[$i]->{keys}->[$j] eq $scnd->[$i]->{keys}->[$j]);
            }
        } else {
            croak "Unsupported thing in the path (step #$i)";
        }
        $i++;
    }

    return @{$scnd}[$i..$#{$scnd}];
}

=head1 LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

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

L<Data::Diver> L<Data::DPath> L<Data::DRef> L<Data::Focus> L<Data::Hierarchy> L<Data::Nested> L<Data::PathSimple>
L<Data::Reach> L<Data::Spath> L<JSON::Path> L<MarpaX::xPathLike> L<Sereal::Path> L<Data::Find>

L<Struct::Diff> L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
