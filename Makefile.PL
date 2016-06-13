use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Struct::Path',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Struct/Path.pm',
    ABSTRACT_FROM    => 'lib/Struct/Path.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Data::Dumper'  => 0,
        'Storable'      => 0,
        'Test::More'    => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Struct-Path.pm',
        },
    },
    PREREQ_PM => {
        'Carp'       => 0,
        'parent'     => 0,
        'strict'     => 0,
        'warnings'   => 0,
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => { FILES => 'Struct-Path-*' },
);
