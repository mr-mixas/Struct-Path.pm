#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 24;

use Struct::Path qw(spath);

use Storable qw(freeze);
$Storable::canonical = 1;

use lib "t";
use _common qw($s_array $s_mixed scmp);

my (@r, $frozen_s);

# will check later it's not chaged
$frozen_s = freeze($s_mixed);

# path must be a list
eval { spath($s_mixed, undef) };
ok($@ =~ /^Path must be arrayref/);

# garbage in the path
eval { spath($s_mixed, [ 'a' ]) };
ok($@ =~ /^Unsupported thing in the path \(step #0\)/);

# garbage in hash definition1
eval { spath($s_mixed, [ {garbage => ['a']} ]) };
ok($@ =~ /^Unsupported HASH definition \(step #0\)/); # must be error

# garbage in hash definition1
eval { spath($s_mixed, [ {keys => 'a'} ]) };
ok($@ =~ /^Unsupported HASH definition \(step #0\)/); # must be error

# wrong step type, strict
eval { spath($s_mixed, [ [0] ], strict => 1) };
ok($@ =~ /^Passed struct doesn't match provided path \(array expected on step #0\)/);

# wrong step type, strict 2
eval { spath($s_array, [ {keys => 'a'} ], strict => 1) };
ok($@ =~ /^Passed struct doesn't match provided path \(hash expected on step #0\)/);

# out of range
eval { spath($s_mixed, [ {keys => ['a']},[1000] ]) };
ok(!$@); # must be no error

# out of range, but strict opt used
eval { spath($s_mixed, [ {keys => ['a']},[1000] ], strict => 1) };
ok($@); # must be error

# hash key doesn't exists
eval { spath($s_mixed, [ {keys => ['notexists']} ]) };
ok(!$@); # must be no error

# hash key doesn't exists, but strict opt used
eval { spath($s_mixed, [ {keys => ['notexists']} ], strict => 1) };
ok($@); # must be error

# path doesn't exists
@r = spath($s_mixed, [ [],{keys => ['c']} ]);
ok(!@r);

# path doesn't exists
@r = spath($s_mixed, [ {keys => ['a']},{} ]);
ok(!@r);

# must return full struct
@r = spath($s_mixed, []);
ok($frozen_s = freeze(${$r[0]}));

# nonref as a structure
@r = spath(undef, []);
ok(scmp(
    \@r,
    [\undef],
    "nonref as a structure"
));

# blessed thing as a structure
my $t = bless {}, "Thing";
@r = spath($t, []);
ok(scmp(
    \@r,
    [bless( {}, 'Thing' )],
    "blessed thing as a structure"
));

# get
@r = spath($s_mixed, [ {keys => ['b']} ]);
ok(scmp(
    \@r,
    [\{ba => 'vba',bb => 'vbb'}],
    "get {b}"
));

# here must be all b's subkeys values
@r = spath($s_mixed, [ {keys => ['b']},{} ]);
ok(scmp(
    [ sort { ${$a} cmp ${$b} } @r ], # access via keys, which returns keys with random order, that's why sort result here
    [\'vba',\'vbb'],
    "get {b}{}"
));

# result must have right sequence
@r = spath($s_array, [ [3],[1] ]);
ok(scmp(
    \@r,
    [\[13]],
    "get [3],[1] from s_array"
));

# result must have right sequence
@r = spath($s_mixed, [ {keys => ['a']},[1],[1, 0] ]);
ok(scmp(
    \@r,
    [\'a1',\'a0'],
    "get {a}[1][1,0]"
));

# result must contain all items from last step
@r = spath($s_mixed, [ {keys => ['a']},[1],[] ]);
ok(scmp(
    \@r,
    [\'a0',\'a1'],
    "get {a}[1][]"
));

# dereference result
@r = spath($s_mixed, [ {keys => ['a']},[1],[] ], deref => 1);
ok(scmp(
    \@r,
    ['a0','a1'],
    "get {a}[1][], deref=1"
));

# mixed structures
@r = spath($s_mixed, [ {keys => ['a']},[0],{keys => ['a2c']} ]);
ok(scmp(
    \@r,
    [\{a2ca => []}],
    "get {a}[0]{a2c}"
));

# original structure must remain unchanged
ok($frozen_s eq freeze($s_mixed));


### set tests ###
@r = spath($s_mixed, [ {keys => ['c']} ]);
${$r[0]} = "vc_replaced";
ok(scmp(
    $s_mixed,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc_replaced'
    },
    "replace {c}"
));

