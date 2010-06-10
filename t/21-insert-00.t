use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataStore';
    require 't/Person1.pm';
}

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
#my $dbh = DBI->connect("DBI:mysql:database=autorun:","root","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE person (uid INTEGER PRIMARY KEY AUTOINCREMENT, cname VARCHAR(64));
EOT

my $ds = MooseX::DataStore->connect($dbh);

my $john = Person->new( name => 'John' );
is $john->id, undef;

is $john->datastore, undef;

$ds->add($john);
is $john->datastore, $ds;
is $john->id, undef;

$ds->flush;
isnt $john->id, undef;

ok $john->id > 0;

my $people = $ds->find( ['Person'], -where => { name => { -like => 'Jo%' } }, -limit => 1 );
is ref($people), 'ARRAY';
is scalar(@$people), 1;
my $jo = $people->[0];

is $jo, $john;

ok 1;
ok 1;


__END__

