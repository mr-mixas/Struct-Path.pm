#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;

use Struct::Path qw(spath);

use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;

my (@r, $s);

$s = {
    'a' => [
        {
            'a2a' => { 'a2aa' => 0 },
            'a2b' => { 'a2ba' => undef },
            'a2c' => { 'a2ca' => [] },
        },
        [ 'a0', 'a1' ],
    ],
    'b' => {
        'ba' => 'vba',
        'bb' => 'vbb',
    },
    'c' => 'vc',
};

eval { spath($s, undef) };                                      # path must be a list
ok($@); # expected error

eval { spath(undef, []) };                                      # struct must be a struct
ok($@); # expected error

eval { spath($s, [ {a => 0},[2] ]) };                           # array item 2 doesn't exists
ok(!$@); # must be no error

eval { spath($s, [ {0 => 'notexists'} ]) };                     # hash key doesn't exists
ok(!$@); # must be no error

@r = spath($s, [ {c => undef} ]);                               # undef as order marker also ok
#print STDERR "\n>>> ", Dumper(@r), " <<<\n";
ok(
    @r == 1
        and ref $r[0] eq 'SCALAR' and ${$r[0]} eq 'vc'
);

${$r[0]} = "vc_replaced";
ok(exists $s->{c} and $s->{c} eq "vc_replaced");                # set value through path

@r = spath($s, [ {b => 0} ]);
#print STDERR "\n>>> ", Dumper(@r), " <<<\n";
ok(
    @r == 1
        and ref $r[0] eq 'REF' and ref ${$r[0]} eq 'HASH' and keys %{${$r[0]}} == 2
            and exists ${$r[0]}->{'ba'} and ${$r[0]}->{'ba'} eq 'vba'
            and exists ${$r[0]}->{'bb'} and ${$r[0]}->{'bb'} eq 'vbb'
);

@r = spath($s, [ {b => 0},{ba => 1, bb => 0} ]);                # check sort
#print STDERR "\n>>> ", Dumper(@r), " <<<\n";
ok(
    @r == 2
        and ref $r[0] eq 'SCALAR' and ${$r[0]} eq 'vbb'
        and ref $r[1] eq 'SCALAR' and ${$r[1]} eq 'vba'
);

@r = spath($s, [ {b => 0},{} ]);                                # here must be all b's subkeys values
#print STDERR "\n>>> ", Dumper(@r), " <<<\n";
# access via keys, which returns keys with random order, that's why sort result here
@r = sort map { ${$_} } @r;
ok(
    @r == 2
        and $r[0] eq 'vba'
        and $r[1] eq 'vbb'
);

@r = spath($s, [ {a => 0},[1],[1, 0] ]);                        # result must have right sequence
#print STDERR "\n>>> ", Dumper(\@r), " <<<\n";
ok(
    @r == 2
        and ref $r[0] eq 'SCALAR' and ${$r[0]} eq 'a1'
        and ref $r[1] eq 'SCALAR' and ${$r[1]} eq 'a0'
);

@r = spath($s, [ {a => 0},[1],[] ]);                            # result must contain all items from last step
#print STDERR "\n>>> ", Dumper(\@r), " <<<\n";
ok(
    @r == 2
        and ref $r[0] eq 'SCALAR' and ${$r[0]} eq 'a0'
        and ref $r[1] eq 'SCALAR' and ${$r[1]} eq 'a1'
);

@r = spath($s, [ {a => 0},[0],{a2c => 1} ]);                    # mixed structures
#print STDERR "\n>>> ", Dumper(@r), " <<<\n";
ok(
    @r == 1
        and ref $r[0] eq 'REF' and ref ${$r[0]} eq 'HASH' and keys %{${$r[0]}} == 1
            and exists ${$r[0]}->{'a2ca'} and ref ${$r[0]}->{'a2ca'} eq 'ARRAY'
                and @{${$r[0]}->{'a2ca'}} == 0
);
