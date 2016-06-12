#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use Struct::Path qw(spath);

use Storable qw(dclone);

use lib "t";
use _common qw($s_mixed scmp);

my (@r, $tmp);

$tmp = \undef;
eval { @r = spath($tmp, [ {a => 0},[3] ], expand => 1) };
ok($@ =~ /^Stuct must be reference to ARRAY or HASH at/);            # Allow here to expand from undef?

$tmp = dclone($s_mixed);
eval { @r = spath($tmp, [ {b => 0},[0] ], expand => 1) };
ok($@ =~ /^Passed struct doesn't match provided path \(array expected on step #1\) at/);

$tmp = dclone($s_mixed);
eval { @r = spath($tmp, [ {a => 0},[1],{a1a => 0} ], expand => 1) };
ok($@ =~ /^Passed struct doesn't match provided path/);

### ARRAYS ###

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {a => 0},[3] ], expand => 1);
ok(scmp(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1'],undef,undef],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc'
    },
    "create {a}[3]"
));

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {a => 0},[3],[1] ], expand => 1);
ok(scmp(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1'],undef,[undef,undef]],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc'
    },
    "create {a}[3][1]"
));

### HASHES ###

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {d => 0} ], expand => 1);
ok(scmp(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc',d => undef
    },
    "create {d}"
));

$tmp = dclone($s_mixed);
@r = spath($tmp, [ {d => 0},{da => 0, db => 1} ], expand => 1);
ok(scmp(
    $tmp,
    {
        a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],
        b => {ba => 'vba',bb => 'vbb'},
        c => 'vc',
        d => {da => undef,db => undef}
    },
    "create {d}{da,db}"
));

### MIXED ###

$tmp = {};
@r = spath($tmp, [ {a => 0},[0,3],{ana => 0, anb => 1},[1] ], expand => 1);
ok(scmp(
    $tmp,
    {a => [{ana => [undef,undef],anb => [undef,undef]},undef,undef,{ana => [undef,undef],anb => [undef,undef]}]},
    "expand {a}[0,3]{ana,anb}[1]"
));
