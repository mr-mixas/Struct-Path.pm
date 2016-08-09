package _common;

# common parts for Struct::Path tests

use Data::Dumper;
use parent qw(Exporter);

our @EXPORT_OK = qw($s_array $s_hash $s_mixed scmp);

our $s_array = [ 3, 1, 5, [9, [13], 7], 11];

our $s_hash = {a => 'av', b => {ba => 'vba', vb => 'vbb'}, c => {}};

our $s_mixed = {
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

sub scmp($$$) { # compare structures by data
    my ($got, $exp, $txt) = @_;
    $got = Data::Dumper->new([$got])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
    $exp = Data::Dumper->new([$exp])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
    print STDERR "\nDEBUG: === $txt ===\ngot: $got\nexp: $exp\n" if ($ENV{DEBUG});
    return $got eq $exp;
}

1;
