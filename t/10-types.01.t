use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}
require 't/Types01.pm';

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
#my $dbh = DBI->connect("DBI:mysql:database=autorun:","root","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE company (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR);
EOT
$dbh->do(<<"EOT");
    CREATE TABLE employee (id INTEGER PRIMARY KEY AUTOINCREMENT, company_id INTEGER REFERENCES point (id), name VARCHAR);
EOT

my $ds = MooseX::DataMapper->connect($dbh);

$ds->save_deep( Company->new( name => "Apple" ) );

my $apple = $ds->objects('Company')->get_first;
is $apple->name, 'Apple';
isnt $apple->pk, undef;

$apple->name('Apple Inc.');

$ds->save_deep( Employee->new( name => "Steve Jobs", company => $apple ) ); # inserts the emp, updates the company in one go

my $jobs = $apple->employees->get_first;
is $jobs->name, 'Steve Jobs';
isnt $jobs->id, undef;

is $jobs->company->pk, $apple->pk;

ok 1;

1;

__END__
