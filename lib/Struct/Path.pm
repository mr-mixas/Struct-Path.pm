package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);

our @EXPORT_OK = qw(slist spath);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=head1 VERSION

Version 0.32

=cut

our $VERSION = '0.32';

=head1 SYNOPSIS

    use Struct::Path qw(spath);

    $s = [
        0,
        1,
        {'2a' => {'2aa' => '2aav', '2ab' => '2abv'}},
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
    my @list = ([[], $struct]); # init: [path, lastref]

    my $continue = 1;
    my $depth = 0;
    while ($continue) {
        last if (defined $opts{depth} and $depth >= $opts{depth});
        $continue = 0;
        my @new;
        while (my $path = shift @list) {
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
        @list = @new;
        $depth++;
    }

    return @list;
}

=head2 spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

=head3 Addressing method

It's simple: path is a list of 'steps', each represents nested level in structure. Arrayref as a step
stands for ARRAY in structure and must contain desired indexes or be empty (means "all items"). Sequence for indexes
is important and defines result sequence. Almost the same for HASHES - step must be a hashref, must contain key
C<keys> which value must contain list of desired keys in structure or may be empty (all keys). Sequence
in C<keys> list defines result sequence.

Why existed *Path* libs (L</"SEE ALSO">) not enough?
This scheme has no collisions for paths like '/a/0/c' ('0' may be an array index or a key for hash, depends on passed
structure). In some cases this is important, for example, when you want to define exact path in structure, but
unable to validate it's schema.

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
    my $refs = (ref $struct eq 'ARRAY' or ref $struct eq 'HASH' or not ref $struct) ? [ \$struct ] : [ $struct ]; #init

    my $sc = 0; # step counter
    for my $step (@{$path}) {
        my @new;
        if (ref $step eq 'ARRAY') {
            for my $r (@{$refs}) {
                unless (ref ${$r} eq 'ARRAY') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r})) {
                        croak "Passed struct doesn't match provided path (array expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }

                if (@{$step}) {
                    for my $i (@{$step}) {
                        unless ($opts{expand} or @{${$r}} > $i) {
                            croak "Item with index '$i' doesn't exists in array (step #$sc)" if $opts{strict};
                            next;
                        }
                        push @new, \${$r}->[$i];
                    }
                    map { splice(@{${$r}}, $_) } reverse sort @{$step} if ($opts{delete} and $sc + 1 == @{$path});
                } else { # [] in the path
                    for (my $i = $#${$r}; $i >= 0; $i--) {
                        unshift @new, \${$r}->[$i];
                        splice(@{${$r}}, $i) if ($opts{delete} and $sc + 1 == @{$path});
                    }
                }
            }
        } elsif (ref $step eq 'HASH') {
            for my $r (@{$refs}) {
                unless (ref ${$r} eq 'HASH') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r})) {
                        croak "Passed struct doesn't match provided path (hash expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }
                if (keys %{$step}) {
                    croak "Unsupported HASH definition (step #$sc)"
                        unless (exists $step->{keys} and ref $step->{keys} eq 'ARRAY');
                    for my $key (@{$step->{keys}}) {
                        unless ($opts{expand} or exists ${$r}->{$key}) {
                            croak "Key '$key' doesn't exists in hash (step #$sc)" if $opts{strict};
                            next;
                        }
                        push @new, \${$r}->{$key};
                        delete ${$r}->{$key} if ($opts{delete} and $sc + 1 == @{$path});
                    }
                } else { # {} in the path
                    for my $key (keys %{${$r}}) {
                        push @new, \${$r}->{$key};
                        delete ${$r}->{$key} if ($opts{delete} and $sc + 1 == @{$path});
                    }
                }
            }
        } else {
            croak "Unsupported thing in the path (step #$sc)";
        }
        $refs = \@new;
        $sc++;
    }

    return $opts{deref} ? map { $_ = ${$_} } @{$refs} : @{$refs};
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
