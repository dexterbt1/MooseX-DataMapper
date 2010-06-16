use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
    require 't/XPointRect.pm';
}

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE x (id INTEGER PRIMARY KEY AUTOINCREMENT, a INTEGER, b VARCHAR(64));
EOT
$dbh->do(<<"EOT");
    CREATE TABLE point (id INTEGER PRIMARY KEY AUTOINCREMENT, x INTEGER, y INTEGER);
EOT
$dbh->do(<<"EOT");
    CREATE TABLE rect (id INTEGER PRIMARY KEY AUTOINCREMENT, point_id INTEGER REFERENCES point (id), width INTEGER, height INTEGER);
EOT

my $ds;

dies_ok {
    $ds = MooseX::DataMapper->connect( DBI->connect("dbi:SQLite:dbname=:memory:","","") );
} 'raise error needed';

$ds = MooseX::DataMapper->connect($dbh);

my ($i, $o);

$i = X->new( a => 1, b => "Hello" );

$i->set_b("Hello World");

$ds->save($i);

$o = $ds->objects('X')->filter('a = ?', 1)->get_first;

isa_ok $o, 'X';
is $o->a, 1;
is $o->get_b, "Hello World";

# =================== 

my ($p, $r);

$p = Point->new( x => 0, y => 0 );
$r = Rect->new( width => 20, height => 10, point => $p );
$ds->save_deep( $r, 1 );

isnt $p->id, undef;
isnt $r->get_point_id, undef;

$ds->delete( $p );

is $p->id, undef;

my $r2 = Rect->new( width => 5, height => 3 );

ok 1;



1;

__END__
