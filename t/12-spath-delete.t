#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
use Test::More tests => 14;

use Struct::Path qw(spath);

sub scmp($$$) {
    my $got = Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    my $exp = Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Dump();
    print STDERR "\nDEBUG: === " . shift . " ===\ngot: $got\nexp: $exp\n" if ($ENV{DEBUG});
    return $got eq $exp;
}

my (@r, $s, $t);

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

# delete single hash key
$t = dclone($s);
@r = spath($t, [ {b => 0} ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],c => 'vc'},
    "delete {b}"
));

ok(scmp(
    \@r,
    [\{ba => 'vba',bb => 'vbb'}],
    "delete {b}:: check returned value"
));

# delete single hash key, two steps
$t = dclone($s);
@r = spath($t, [ {b => 0},{ba => 0} ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {bb => 'vbb'},c => 'vc'},
    "delete {b}{ba}"
));

ok(scmp(
    \@r,
    [\'vba'],
    "delete {b}{ba}:: check returned value"
));

# delete all hash substruct
$t = dclone($s);
@r = spath($t, [ {b => 0},{} ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0','a1']],b => {},c => 'vc'},
    "delete {b}{}"
));

ok(scmp(
    [ sort { ${$a} cmp ${$b} } @r ], # hash keys returned by hash seed (ie randomely, so, sort them)
    [\'vba',\'vbb'],
    "delete {b}{}:: check returned value"
));

# delete single array item
$t = dclone($s);
@r = spath($t, [ {a => 0},[1] ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}}],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1]"
));

ok(scmp(
    \@r,
    [\['a0','a1']],
    "delete {a}[1]:: check returned value"
));

# delete deep single array item
$t = dclone($s);
@r = spath($t, [ {a => 0},[1],[1] ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1][1]"
));

ok(scmp(
    \@r,
    [\'a1'],
    "delete {a}[1][1]:: check returned value"
));

# delete all array's items
$t = dclone($s);
@r = spath($t, [ {a => 0},[1],[] ], delete => 1);
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},[]],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[1][]"
));

ok(scmp(
    \@r,
    [\'a0',\'a1'],
    "delete {a}[1][]:: check returned value"
));

# empty array in the middle of the path
$t = dclone($s);
@r = spath($t, [ {a => 0},[],[1] ], delete => 1); # ok without 'strict'
ok(scmp(
    $t,
    {a => [{a2a => {a2aa => 0},a2b => {a2ba => undef},a2c => {a2ca => []}},['a0']],b => {ba => 'vba',bb => 'vbb'},c => 'vc'},
    "delete {a}[][1]"
));

ok(scmp(
    \@r,
    [\'a1'],
    "delete {a}[][1]:: check returned value"
));

