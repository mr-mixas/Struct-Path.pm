#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 14;
use Test::Deep;

use Struct::Path qw(spath_delta);

my @delta;

eval { spath_delta(['garbage'],['garbage'])};
ok($@ =~ /Unsupported thing in the path \(step #0\)/);

eval {
    @delta = spath_delta(
        [ {keys => ['a']},[0,3],{keys => ['ana', 'anc']},[1] ],
        undef
    );
};
ok($@ =~ /^Second path must be an arrayref/);

eval { spath_delta('garbage', [ [0] ]) };
ok($@ =~ /^First path may be undef or an arrayref/);

@delta = spath_delta(
    undef,
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anc']},[1] ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anc']},[1] ],
    "First path is undef"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [],
    "Equal paths"
);

@delta = spath_delta(
    [ [0,3],{keys => ['a']},{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    "Totally different paths"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']} ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [ [1] ],
    "One step added"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']} ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']} ],
    "One step removed"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [ [0],{keys => ['ana', 'anb']},[1] ],
    "One array step item removed in the middle of the path"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3,4],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [ [0,3,4],{keys => ['ana', 'anb']},[1] ],
    "One array step item added in the middle of the path"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,4],{keys => ['ana', 'anb']},[1] ]
);
cmp_deeply(
    \@delta,
    [ [0,4],{keys => ['ana', 'anb']},[1] ],
    "One array step item changed in the middle of the path"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana']},[1] ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['ana']},[1] ],
    "One hash step item removed in the middle of the path"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb', 'anc']},[1] ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['ana', 'anb', 'anc']},[1] ],
    "One hash step item added in the middle of the path"
);

@delta = spath_delta(
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anb']},[1] ],
    [ {keys => ['a']},[0,3],{keys => ['ana', 'anc']},[1] ]
);
cmp_deeply(
    \@delta,
    [ {keys => ['ana', 'anc']},[1] ],
    "One hash step item changed in the middle of the path"
);
