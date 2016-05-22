# NAME

Struct::Path - Path for nested structures where path is also a structure

# VERSION

Version 0.10

# SYNOPSIS

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

    $r[1] =~ s/2a/blah-blah-/;
    # $s->[2]{2a}{2aa} == "blah-blah-av"

# EXPORT

Nothing exports by default.

# SUBROUTINES

## spath

Returns list of refs from structure.

    @list = spath($struct, $path, %opts)

### Available options

- delete

    Delete specified by path items from structure.

- deref

    Dereference result items if set to some true value.

- strict

    Croak if at least one element, specified in path, absent in the struct.

# LIMITATIONS

No object oriented interface provided.

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-struct-path at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path). I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Struct-Path](http://annocpan.org/dist/Struct-Path)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Struct-Path](http://cpanratings.perl.org/d/Struct-Path)

- Search CPAN

    [http://search.cpan.org/dist/Struct-Path/](http://search.cpan.org/dist/Struct-Path/)

# SEE ALSO

[Data::Diver](https://metacpan.org/pod/Data::Diver) [Data::DPath](https://metacpan.org/pod/Data::DPath) [Data::DRef](https://metacpan.org/pod/Data::DRef) [Data::Focus](https://metacpan.org/pod/Data::Focus) [Data::Hierarchy](https://metacpan.org/pod/Data::Hierarchy) [Data::Nested](https://metacpan.org/pod/Data::Nested) [Data::PathSimple](https://metacpan.org/pod/Data::PathSimple)
[Data::Reach](https://metacpan.org/pod/Data::Reach) [Data::Spath](https://metacpan.org/pod/Data::Spath) [JSON::Path](https://metacpan.org/pod/JSON::Path) [MarpaX::xPathLike](https://metacpan.org/pod/MarpaX::xPathLike) [Sereal::Path](https://metacpan.org/pod/Sereal::Path)

[Struct::Diff](https://metacpan.org/pod/Struct::Diff)

# LICENSE AND COPYRIGHT

Copyright 2016 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.