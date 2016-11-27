package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);

our @EXPORT_OK = qw(slist spath spath_delta);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=head1 VERSION

Version 0.51

=cut

our $VERSION = '0.51';

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

    @list = slist($s);                              # get all paths and their values
    # @list == (
    #    [[[0]],0],
    #    [[[1]],1],
    #    [[[2],{keys => ['2a']},{keys => ['2aa']}],'2aav'],
    #    [[[2],{keys => ['2a']},{keys => ['2ab']}],'2abv'],
    #    [[[3]],undef]
    # )

    @r = spath($s, [ [3,0,1] ]);                    # get refs to values by paths
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{keys => ['2a']},{} ]);    # same, another example
    # @r == (\'2aav', \'2abv')

    ${$r[0]} =~ s/2a/blah-blah-/;                   # replace substructire by path
    # $s->[2]{2a}{2aa} eq "blah-blah-av"

    @d = spath_delta([[0],[4],[2]], [[0],[1],[3]]); # new steps relatively for first path
    # @d == ([1],[3])

=head1 EXPORT

Nothing is exported by default.

=head1 SUBROUTINES

=head2 slist

Returns list of paths and their values from structure.

    @list = slist($struct, %opts)

=head3 Available options

=over 4

=item depth C<< <N> >>

Don't dive into structure deeper than defined level.

=back

=cut

sub slist($;@) {
    my ($struct, %opts) = @_;
    my @out = [[], $struct]; # init: [path, lastref]

    my $continue = 1;
    my $depth = 0;
    while ($continue) {
        last if (defined $opts{depth} and $depth >= $opts{depth});
        $continue = 0;
        my @new;
        while (my $path = shift @out) {
            if (ref $path->[1] eq 'ARRAY' and @{$path->[1]}) {
                for (my $i = 0; $i < @{$path->[1]}; $i++) {
                    push @new, [[@{$path->[0]}, [$i]], $path->[1]->[$i]];
                }
                $continue = 1;
            } elsif (ref $path->[1] eq 'HASH' and keys %{$path->[1]}) {
                for my $k (sort keys %{$path->[1]}) {
                    push @new, [[@{$path->[0]}, {keys => [$k]}], $path->[1]->{$k}];
                }
                $continue = 1;
            } else {
                push @new, $path; # complete path
            }
        }
        @out = @new;
        $depth++;
    }

    return @out;
}

=head2 spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

=head3 Addressing method

Path is a list of 'steps', each represents nested level in structure.

Arrayref as a step stands for ARRAY in structure and must contain desired indexes or be
empty (means "all items"). Sequence for indexes is important and defines result sequence.

Almost the same for HASHES: step must be a hashref, must contain key C<keys> which
value must contain list of desired keys in structure. Empty list means all keys. Sequence
in C<keys> list defines result sequence.

Since v0.50 coderefs as steps supported as well. Path as first argument and stack of references
(arrayref) as second will be passed to it's input, some true value or undef (if error occur)
expected as output.

Why existed *Path* libs (L</"SEE ALSO">) not enough?
This scheme has no collisions for paths like '/a/0/c' ('0' may be an ARRAY index or a key
for HASH, depends on passed structure). In some cases this is important, for example, when
you want to define exact path in structure, but unable to validate it's schema.

See L<Struct::Path::PerlStyle> if you're looking for human friendly path definition method.

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
    my ($struct, $path, %opts) = @_;
    croak "Path must be arrayref" unless (ref $path eq 'ARRAY');
    my @out = (ref $struct eq 'ARRAY' or ref $struct eq 'HASH' or not ref $struct) ?
        [[], [\$struct]] : [[], [$struct]]; # init stacks

    my $sc = 0; # step counter
    for my $step (@{$path}) {
        my @new;
        if (ref $step eq 'ARRAY') {
            while (my $r = shift @out) {
                unless (ref ${$r->[1]->[-1]} eq 'ARRAY') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r->[1]->[-1]})) {
                        croak "Passed struct doesn't match provided path (array expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }
                if (@{$step}) {
                    for my $i (@{$step}) {
                        unless ($opts{expand} or @{${$r->[1]->[-1]}} > $i) {
                            croak "Item with index '$i' doesn't exists in array (step #$sc)" if $opts{strict};
                            next;
                        }
                        push @new, [ [@{$r->[0]}, $i], [@{$r->[1]}, \${$r->[1]->[-1]}->[$i]] ];
                    }
                    map { splice(@{${$r->[1]->[-1]}}, $_, 1) } reverse sort @{$step}
                        if ($opts{delete} and $sc + 1 == @{$path});
                } else { # [] in the path
                    for (my $i = $#${$r->[1]->[-1]}; $i >= 0; $i--) {
                        unshift @new, [ [@{$r->[0]}, $i], [@{$r->[1]}, \${$r->[1]->[-1]}->[$i]] ];
                        splice(@{${$r->[1]->[-1]}}, $i) if ($opts{delete} and $sc + 1 == @{$path});
                    }
                }
            }
        } elsif (ref $step eq 'HASH') {
            while (my $r = shift @out) {
                unless (ref ${$r->[1]->[-1]} eq 'HASH') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r->[1]->[-1]})) {
                        croak "Passed struct doesn't match provided path (hash expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }
                if (keys %{$step}) {
                    croak "Unsupported HASH definition (step #$sc)"
                        unless (exists $step->{keys} and ref $step->{keys} eq 'ARRAY');
                    for my $k (@{$step->{keys}}) {
                        unless ($opts{expand} or exists ${$r->[1]->[-1]}->{$k}) {
                            croak "Key '$k' doesn't exists in hash (step #$sc)" if $opts{strict};
                            next;
                        }
                        push @new, [ [@{$r->[0]}, $k], [@{$r->[1]}, \${$r->[1]->[-1]}->{$k}] ];
                        delete ${$r->[1]->[-1]}->{$k} if ($opts{delete} and $sc + 1 == @{$path});
                    }
                } else { # {} in the path
                    for my $k (keys %{${$r->[1]->[-1]}}) {
                        push @new, [ [@{$r->[0]}, $k], [@{$r->[1]}, \${$r->[1]->[-1]}->{$k}] ];
                        delete ${$r->[1]->[-1]}->{$k} if ($opts{delete} and $sc + 1 == @{$path});
                    }
                }
            }
        } elsif (ref $step eq 'CODE') {
            for my $r (@out) {
                $step->($r->[0], $r->[1]) or croak "Failed to apply user defined function (step #$sc)";
                push @new, $r;
            }
        } else {
            croak "Unsupported thing in the path (step #$sc)";
        }
        @out = @new;
        $sc++;
    }

    @out = map { pop @{$_->[1]} } @out; # prev out support
    return $opts{deref} ? map { $_ = ${$_} } @out : @out;
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
    MAIN: while ($i < @{$frst}) {
        last unless (ref $frst->[$i] eq ref $scnd->[$i]);
        if (ref $frst->[$i] eq 'ARRAY') {
            last unless (@{$frst->[$i]} == @{$scnd->[$i]});
            my $j = 0;
            while ($j < @{$frst->[$i]}) {
                last MAIN unless ($frst->[$i]->[$j] == $scnd->[$i]->[$j]);
                $j++;
            }
        } elsif (ref $frst->[$i] eq 'HASH') {
            last unless (@{$frst->[$i]->{keys}} == @{$scnd->[$i]->{keys}});
            my $j = 0;
            while ($j < @{$frst->[$i]->{keys}}) {
                last MAIN unless ($frst->[$i]->{keys}->[$j] eq $scnd->[$i]->{keys}->[$j]);
                $j++;
            }
        } else {
            croak "Unsupported thing in the path (step #$i)";
        }
        $i++;
    }

    return @{$scnd}[$i..$#{$scnd}];
}

=head1 LIMITATIONS

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
L<Data::Reach> L<Data::Spath> L<JSON::Path> L<MarpaX::xPathLike> L<Sereal::Path>

L<Struct::Diff> L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
