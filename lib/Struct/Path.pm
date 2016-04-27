package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Exporter);
use Carp qw(croak);

BEGIN { our @EXPORT_OK = qw(spath) }

=head1 NAME

Struct::Path - path for nested structures where path is also a structure

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Struct::Path;

    $s = [
        0,
        1,
        {2a => {2aa => '2aav', 2ab => '2abv'}},
        undef
    ];

    $r = spath($s, [ [3,0,1] ]);
    # $r == [\undef, \0, \1]

    $r = spath($s, [ [2],{2a => undef},{} ]);
    # $r == [\2aav, \2abv]

    ${$r[1]} =~ s/2a/blah-blah-/;
    # $s->[2]{2a}{2aa} == "blah-blah-av"
    # $s->[2]{2a}{2ab} == "blah-blah-ab"
    ...

=head1 EXPORT

Nothing exports by default.

=head1 SUBROUTINES

=head2 spath

Returns list of refs from structure.

=cut

sub spath($$;@) {
    my ($ref, $path, %opts) = @_;
    croak "Stuct must be reference to ARRAY or HASH" unless (ref $ref eq 'ARRAY' or ref $ref eq 'HASH');
    croak "Path must be arrayref" unless (ref $path eq 'ARRAY');
    my $refs = [ \$ref ];

    my $sc = 0; # step counter
    for my $step (@{$path}) {
        my @new;
        if (ref $step eq 'ARRAY') {
            if (@{$step}) {
                for my $i (@{$step}) {
                    for my $r (@{$refs}) {
                        next unless (ref ${$r} eq 'ARRAY'); # TODO: test me
                        push @new, \${$r}->[$i] if (@{${$r}} > $i);
                    }
                }
            } else { # [] in the path
                for my $r (@{$refs}) {
                    next unless (ref ${$r} eq 'ARRAY'); # TODO: test me
                    for my $i (@{${$r}}) {
                        push @new, \$i;
                    }
                }
            }
        } elsif (ref $step eq 'HASH') {
            for my $r (@{$refs}) {
                next unless (ref ${$r} eq 'HASH'); # TODO: test me
                if (keys %{$step}) {
                    for my $key (sort { $step->{$a} <=> $step->{$b} } keys %{$step}) {
                        push @new, \${$r}->{$key} if (exists ${$r}->{$key});
                    }
                } else { # {} in the path
                    for my $key (keys %{${$r}}) {
                        push @new, \${$r}->{$key};
                    }
                }
            }
        } else {
            croak "Unsupported thing in the path (in position $sc)";
        }
        $refs = \@new;
        $sc++;
    }

    return @{$refs};
}

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

L<JSON::Path>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
