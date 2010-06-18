use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use DateTime;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}
use MooseX::DataMapper::ColumnHandlers::DateTime qw/to_date from_date/;

require 't/lib/DateTime1.pm';

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE person (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name VARCHAR,
        birth_date DATE,
        birth_date_copy DATE
    )
EOT

my $ds;

dies_ok {
    $ds = MooseX::DataMapper->connect( DBI->connect("dbi:SQLite:dbname=:memory:","","") );
} 'raise error needed';

$ds = MooseX::DataMapper->connect($dbh);

my $p = Person->new( name => 'John', birth_date => DateTime->new( year => 1980, month => 12, day => 31 ) );

is $p->birth_date->year, 1980;
is $p->birth_date->month, 12;
is $p->birth_date->day, 31;

is $p->pk, undef;

$ds->save( $p );

isnt $p->pk, undef;

my $p2 = $ds->objects('Person')->first;

is $p2->pk, $p->pk;
is $p2->birth_date->year, 1980;
is $p2->birth_date->month, 12;
is $p2->birth_date->day, 31;

# change birth_date

$p2->birth_date( DateTime->new( year => 2010, month => 1, day => 23 ) );

$ds->save($p2);

my $p3 = $ds->objects('Person')->get( $p2->pk );

is $p3->pk, $p2->pk;
is $p3->birth_date->year, 2010;
is $p3->birth_date->month, 1;
is $p3->birth_date->day, 23;

$p3->birth_date_copy( $p3->birth_date );
isnt $p3->birth_date_copy, undef;
$ds->save($p3);

$p = $ds->objects('Person')->first;
is $p->birth_date_copy->year, 2010;
is $p->birth_date_copy->month, 1;
is $p->birth_date->day, 23;



ok 1;



1;

__END__
