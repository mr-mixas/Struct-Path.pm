package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);

our @EXPORT_OK = qw(spath);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Struct::Path qw(spath);

    $s = [
        0,
        1,
        {2a => {2aa => '2aav', 2ab => '2abv'}},
        undef
    ];

    @r = spath($s, [ [3,0,1] ]);
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{2a => undef},{} ]);
    # @r == (\2aav, \2abv)

    ${$r[0]} =~ s/2a/blah-blah-/;
    # $s->[2]{2a}{2aa} == "blah-blah-av"

=head1 EXPORT

Nothing exports by default.

=head1 SUBROUTINES

=head2 spath

Returns list of refs from structure.

    @list = spath($struct, $path, %opts)

=head3 Available options

=over 4

=item delete

Delete specified by path items from structure.

=item deref

Dereference result items if set to some true value.

=item expand

Expand structure if specified in path items does't exists. All newly created items initialized by undef.

=item strict

Croak if at least one element, specified in path, absent in the struct.

=back

=cut

sub spath($$;@) {
    my ($struct, $path, %opts) = @_;
    croak "Stuct must be reference to ARRAY or HASH" unless (ref $struct eq 'ARRAY' or ref $struct eq 'HASH');
    croak "Path must be arrayref" unless (ref $path eq 'ARRAY');
    my $refs = [ \$struct ]; # init

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
                    for (my $i = @{${$r}} - 1; $i >= 0; $i--) {
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
                    for my $key (sort { $step->{$a} <=> $step->{$b} } keys %{$step}) {
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

L<Struct::Diff>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
