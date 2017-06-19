# NAME

Struct::Path - Path for nested structures where path is also a structure

# VERSION

Version 0.70

# SYNOPSIS

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

    @list = slist($s);                              # list paths and their values
    # @list == (
    #     [[0]], \0,
    #     [[1]], \1,
    #     [[2],{keys => ['2a']},{keys => ['2aa']}], \'2aav',
    #     [[2],{keys => ['2a']},{keys => ['2ab']}], \'2abv',
    #     [[3]], \undef
    # )

    @r = spath($s, [ [3,0,1] ]);                    # get refs to values
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{keys => ['2a']},{} ]);    # same, another example
    # @r == (\'2aav', \'2abv')

    @r = spath($s, [ [2],{},{regs => [qr/^2a/]} ]); # or using regular expressions
    # @r == (\'2aav', \'2abv')

    ${$r[0]} =~ s/2a/blah-blah-/;                   # replace
    # $s->[2]{2a}{2aa} eq "blah-blah-av"

    @d = spath_delta([[0],[4],[2]], [[0],[1],[3]]); # get steps delta
    # @d == ([1],[3])

# DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data structures.

Why existed \*Path\* modules (["SEE ALSO"](#see-also)) is not enough? This module has no
conflicts for paths like '/a/0/c', where `0` may be an ARRAY index or a key for
HASH (depends on passed structure). In some cases this is important, for example,
when one need to define exact path in structure, but unable to validate it's
schema or when structure itself doesn't yet exists (see ["spath/Options/expand"](#spath-options-expand)
for example).

# EXPORT

Nothing is exported by default.

# ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in structure.

Arrayref as a step stands for ARRAY in structure and must contain desired indexes
or be empty (means "all items"). Sequence for indexes is important and defines
result sequence.

Hashref represents HASH in the structure and may contain keys `keys`, `regs` or be
empty. `keys` may contain list of desired keys, `regs` must contain list of regular
expressions. Empty hash or empty list for `keys` means all keys. Sequence in `keys`
and `regs` lists defines result sequence. `keys` have higher priority than `regs`.

Sample:

    $spath = [
        [1,7],              # first spep
        {regs => qr/foo/}   # second step
    ];

Since v0.50 hooks (coderefs) as steps supported. Path as first argument and stack
of references (arrayref) as second passed to it when executed. Some true (match)
value or false (doesn't match) value expected as output.

See [Struct::Path::PerlStyle](https://metacpan.org/pod/Struct::Path::PerlStyle) if you're looking for human friendly path definition
method.

# SUBROUTINES

## is\_implicit\_step

    $implicit = is_implicit_step($step);

Returns true value if step contains hooks or specified all items or regexp match.

## slist

Returns list of paths and references to their values from structure.

    @list = slist($struct, %opts)

### Options

- depth `<N>`

    Don't dive into structure deeper than defined level.

## spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

### Options

- delete `<true|false>`

    Delete specified by path items from structure.

- deref `<true|false>`

    Dereference result items.

- expand `<true|false>`

    Expand structure if specified in path items does't exists. All newly created items
    initialized by `undef`.

- paths `<true|false>`

    Return path for each result.

- stack `<true|false>`

    Return stack of references to substructures.

- strict `<true|false>`

    Croak if at least one element, specified by path, absent in the structure.

All options are disabled (`undef`) by default.

## spath\_delta

Returns delta for two passed paths. By delta means steps from the second path
without beginning common steps for both.

    @delta = spath_delta($path1, $path2)

# LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-struct-path at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path). I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

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

[Struct::Diff](https://metacpan.org/pod/Struct::Diff) [Struct::Path::PerlStyle](https://metacpan.org/pod/Struct::Path::PerlStyle)

# LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
