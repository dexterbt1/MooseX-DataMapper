use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}
require 't/Types02.pm';

# --------------- in database operations


my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
#my $dbh = DBI->connect("DBI:mysql:database=autorun:","root","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE company (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR);
EOT
$dbh->do(<<"EOT");
    CREATE TABLE employee (id INTEGER PRIMARY KEY AUTOINCREMENT, company_id INTEGER REFERENCES point (id), name VARCHAR);
EOT

my $ds = MooseX::DataMapper->connect($dbh);

my $msft = Company->new( name => 'Microsoft' );
$ds->save( $msft );

$msft->employees->save( Employee->new( name => 'Bill Gates' ) );
$msft->employees->save( Employee->new( name => 'Steve Balmer' ) );

my $msft_employees = $msft->employees->get_objects;

is scalar @$msft_employees, 2;

my $apple = Company->new( name => 'Apple' );
$ds->save( $apple );

my $johndoe = Employee->new( name => 'John Doe' );
is $johndoe->pk, undef;
is $johndoe->company, undef;
$apple->employees->save( $johndoe );
isnt $johndoe->pk, undef;
is $johndoe->company, $apple;

is scalar(@{$apple->employees->get_objects}), 1;

# transfer john doe from apple to msft

$msft->employees->save( $johndoe );

is $johndoe->company, $msft;

is scalar(@{$msft->employees->get_objects}), 3;




ok 1;

1;

__END__
