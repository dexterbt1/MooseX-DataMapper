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
$dbh->do(<<"EOT");
    CREATE TABLE address (id INTEGER PRIMARY KEY AUTOINCREMENT, city VARCHAR(64), person_uid INTEGER REFERENCES person (uid) );
EOT

my $ds = MooseX::DataStore->connect($dbh);

my $john = Person->new( name => 'John' );
is $john->id, undef;

is $john->datastore, undef;

$ds->save($john);
isnt $john->id, undef;
is $john->name, 'John';

ok $john->id > 0;

my $people;

$people = $ds->find('Person')->rows;
is ref($people), 'ARRAY';
is scalar(@$people), 1;
my $jo = $people->[0];

is $jo->name, 'John';

is $jo, $john; # same reference

# update

$jo->name('Johnny');
$ds->save($jo);

my $j = $ds->find('Person')->get($jo->pk);
is $j->name, 'Johnny';

is $j, $jo;
is $j, $john;

my $bob = Person->new( name => 'Bob' );
$ds->save($bob);

$people = $ds->find('Person')->rows;
is scalar(@$people), 2;

$people = $ds->find('Person')->filter('name like ?', '%ohn%')->rows;
is scalar(@$people), 1;
is $j->name, 'Johnny';
is $j, $john;
is $j, $jo;

$people = $ds->find('Person')
             ->filter('name like ?', 'john%')
             ->or
             ->filter({ id => { -in => [ 1, 2 ] } })
             ->rows;

is scalar @$people, 2;

# basic foreign key tests

ok defined( Address->meta->primary_key );

my $johns_addr = Address->new( city => 'New York' );
isa_ok $johns_addr, 'Address';

$johns_addr->person( $john );
$ds->save($johns_addr);

my $johns_addr_copy = $ds->find('Address')->get(1);
is $johns_addr_copy, $johns_addr;

is $johns_addr->person_id, $john->pk;
isnt $johns_addr->person, $john;
isnt $johns_addr->person, $jo;

my $matts_addr = Address->new(
    city    => "London",
    person  => Person->new( name => "Matt" ),
);
$ds->save($matts_addr);

isnt $matts_addr->pk, undef;
isnt $matts_addr->person_id, undef;
$people = $ds->find('Person')->filter("name = ?", "Matt")->rows;
my $matt = shift @$people;
ok defined($matt);

is $matt, $matts_addr->person;

# =================================
# start a new session, this means the identity map is cleared

$ds = MooseX::DataStore->connect($dbh);

my $places;
$places = $ds->find('Address')->filter('city = ?', 'London')->limit(1)->rows;
is scalar @$places, 1;

my $addr = $places->[0];
isnt $addr->person, undef;
isa_ok $addr->person, 'Person';
isnt $addr->person, $matt;

$matt = $addr->person;
$places = $ds->find('Address')->filter('city = ?', 'London')->limit(1)->rows;

$addr = $places->[0];
isnt $addr->person, $matt;

$addr->person( Person->new( name => "James" ) );
$ds->save($addr);

is $addr->person->name, 'James';
isnt $addr->person_id, undef;

ok 1;

=cut

$ds->select('Address|a', 'Person|p')
   ->where({ 'a.person_id' => 'p.id' })
   ->AND
   ->where({ 'p.name' => { -like => "Bo%" } })
   ->limit(1)
   ->rows;

$ds->query('Address')
   ->count('id')
   ->row;

$ds->query('Address')
   ->count('id')
   ->group_by('person_id')
   ->rows;

=cut


ok 1;

__END__

