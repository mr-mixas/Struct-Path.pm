# NAME

Struct::Path - Path for nested structures where path is also a structure

<a href="https://travis-ci.org/mr-mixas/Struct-Path.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path"><img src="https://badge.fury.io/pl/Struct-Path.svg" alt="CPAN version"></a>

# VERSION

Version 0.84

# SYNOPSIS

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

# DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data
structures.

Why [existed modules](#see-also) are not enough? This module has no
conflicts for paths like '/a/0/c', where `0` may be an array index or a key
for hash (depends on passed structure). This is vital in some cases, for
example, when one need to define exact path in structure, but unable to
validate it's schema or when structure itself doesn't yet exist (see
option `expand` for ["path"](#path)).

# EXPORT

Nothing is exported by default.

# ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in the structure.

Arrayref as a step stands for ARRAY and must contain desired items indexes or
be empty (means "all items"). Sequence for indexes define result sequence.

Hashref represent HASH and may contain key `K` or be empty. `K`'s value
should be a list of desired keys and compiled regular expressions. Empty
hash or empty list for `K` means all keys, sequence in the list define
resulting sequence.

Coderef step is a hook - subroutine which may filter out items and/or modify
structure. Traversed path for first, stack of passed structured for secong and
path remainder for third agrument passed to hook when executed; all passed args
are arrayrefs. Among this two global variables available within hook: `$_` is
set to current substructure and `$_{opts}` contains c<path()>'s options. Some
true (match) value or false (doesn't match) value expected as output.

Sample:

    $path = [
        [1,7],                      # first spep
        {K => [qr/foo/,qr/bar/]}    # second step
        sub { exists $_->{bar} }    # third step
    ];

Struct::Path designed to be machine-friendly. See [Struct::Path::PerlStyle](https://metacpan.org/pod/Struct::Path::PerlStyle)
and [Struct::Path::JsonPointer](https://metacpan.org/pod/Struct::Path::JsonPointer) for human friendly path definition.

# SUBROUTINES

## implicit\_step

    $bool = implicit_step($step);

Returns true value if step contains hooks or specified 'all' items or regexp
match.

## list\_paths

Returns list of paths and references to their values from structure.

    @list = list_paths($structure, %opts)

### Options

- depth `<N>`

    Don't dive into structure deeper than defined level.

## path

Returns list of references from structure.

    @found = path($structure, $path, %opts)

### Options

- assign `<value>`

    Assign provided value to substructures pointed by path.

- delete `<true|false>`

    Delete specified by path items from structure.

- deref `<true|false>`

    Dereference result items.

- expand `<true|false>`

    Expand structure if specified in path items doesn't exist. All newly created
    items initialized by `undef`.

- paths `<true|false>`

    Return path for each result.

- stack `<true|false>`

    Return stack of references to substructures.

- strict `<true|false>`

    Croak if at least one element, specified by path, absent in the structure.

All options are disabled (`undef`) by default.

## path\_delta

Returns delta for two passed paths. By delta means list of steps from the
second path without beginning common steps for both.

    @delta = path_delta($path1, $path2)

# LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-struct-path at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path). I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

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

[Data::Diver](https://metacpan.org/pod/Data::Diver) [Data::DPath](https://metacpan.org/pod/Data::DPath) [Data::DRef](https://metacpan.org/pod/Data::DRef) [Data::Focus](https://metacpan.org/pod/Data::Focus) [Data::Hierarchy](https://metacpan.org/pod/Data::Hierarchy)
[Data::Nested](https://metacpan.org/pod/Data::Nested) [Data::PathSimple](https://metacpan.org/pod/Data::PathSimple) [Data::Reach](https://metacpan.org/pod/Data::Reach) [Data::Spath](https://metacpan.org/pod/Data::Spath) [JSON::Path](https://metacpan.org/pod/JSON::Path)
[MarpaX::xPathLike](https://metacpan.org/pod/MarpaX::xPathLike) [Sereal::Path](https://metacpan.org/pod/Sereal::Path) [Data::Find](https://metacpan.org/pod/Data::Find)

[Struct::Diff](https://metacpan.org/pod/Struct::Diff) [Struct::Path::PerlStyle](https://metacpan.org/pod/Struct::Path::PerlStyle) [Struct::Path::JsonPointer](https://metacpan.org/pod/Struct::Path::JsonPointer)

# LICENSE AND COPYRIGHT

Copyright 2016-2019 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
