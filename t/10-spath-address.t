#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 20;

use Struct::Path qw(spath);

use Storable qw(freeze);
$Storable::canonical = 1;

use lib "t";
use _common qw($s_mixed scmp);

my (@r, $frozen_s);

$frozen_s = freeze($s_mixed); # check later it's not chaged

eval { spath($s_mixed, undef) };                                # path must be a list
ok($@); # expected error

eval { spath(undef, []) };                                      # struct must be a struct
ok($@); # expected error

eval { spath($s_mixed, [ {a => 0},[1000] ]) };                  # out of range
ok(!$@); # must be no error

eval { spath($s_mixed, [ {a => 0},[1000] ], strict => 1) };     # out of range, but strict opt used
ok($@); # must be error

eval { spath($s_mixed, [ [0] ], strict => 1) };                 # wrong step type, strict
ok($@);

eval { spath($s_mixed, [ {notexists => 0} ]) };                 # hash key doesn't exists
ok(!$@); # must be no error

eval { spath($s_mixed, [ {notexists => 0} ], strict => 1) };    # hash key doesn't exists, but strict opt used
ok($@); # must be error

@r = spath($s_mixed, [ [],{c => 0} ]);                          # path not exists
ok(!@r);

@r = spath($s_mixed, [ {a => 0},{} ]);                          # path not exists
ok(!@r);

@r = spath($s_mixed, []);                                       # must return full struct
ok($frozen_s = freeze(${$r[0]}));

@r = spath($s_mixed, [ {c => undef} ]);                         # undef as order marker also ok
ok(scmp(
    \@r,
    [\'vc'],
    "blah-blah"
));

@r = spath($s_mixed, [ {b => 0} ]);                             # get
ok(scmp(
    \@r,
    [\{ba => 'vba',bb => 'vbb'}],
    "get {b}"
));

@r = spath($s_mixed, [ {b => 0},{ba => 1, bb => 0} ]);          # check sort
ok(scmp(
    \@r,
    [\'vbb',\'vba'],
    "get {b}{bb,ba}"
));

@r = spath($s_mixed, [ {b => 0},{} ]);                          # here must be all b's subkeys values
ok(scmp(
    [ sort { ${$a} cmp ${$b} } @r ], # access via keys, which returns keys with random order, that's why sort result here
    [\'vba',\'vbb'],
    "get {b}{}"
));

@r = spath($s_mixed, [ {a => 0},[1],[1, 0] ]);                  # result must have right sequence
ok(scmp(
    \@r,
    [\'a1',\'a0'],
    "get {a}[1][1,0]"
));

@r = spath($s_mixed, [ {a => 0},[1],[] ]);                      # result must contain all items from last step
ok(scmp(
    \@r,
    [\'a0',\'a1'],
    "get {a}[1][]"
));

@r = spath($s_mixed, [ {a => 0},[1],[] ], deref => 1);          # dereference result
ok(scmp(
    \@r,
    ['a0','a1'],
    "get {a}[1][], deref=1"
));

@r = spath($s_mixed, [ {a => 0},[0],{a2c => 1} ]);              # mixed structures
ok(scmp(
    \@r,
    [\{a2ca => []}],
    "get {a}[0]{a2c}"
));

ok($frozen_s eq freeze($s_mixed));                              # check orig struct unchanged


### set tests ###
@r = spath($s_mixed, [ {c => 0} ]);
${$r[0]} = "vc_replaced";
ok(scmp(
    $s_mixed,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {ba => 'vba',bb => 'vbb'},c => 'vc_replaced'},
    "replace {c}"
));

