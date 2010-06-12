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

$people = $ds->objects('Person')->get_objects;
is ref($people), 'ARRAY';
is scalar(@$people), 1;
my $jo = $people->[0];

is $jo->name, 'John';

isnt $jo, $john; # not the same reference, no identity_map support

# update

$jo->name('Johnny');
$ds->save($jo);

my $j = $ds->objects('Person')->get($jo->pk);
is $j->name, 'Johnny';

my $bob = Person->new( name => 'Bob' );
$ds->save($bob);

$people = $ds->objects('Person')->get_objects;
is scalar(@$people), 2;

$people = $ds->objects('Person')->filter('name like ?', '%ohn%')->get_objects;
is scalar(@$people), 1;
$jo = $people->[0];
is $jo->name, 'Johnny';

$people = $ds->objects('Person')
             ->filter('name like ?', 'john%')
             ->or
             ->filter({ id => { -in => [ 1, 2 ] } })
             ->get_objects;

is scalar @$people, 2;

# basic foreign key tests

ok defined( Address->meta->primary_key );

my $johns_addr = Address->new( city => 'New York' );
isa_ok $johns_addr, 'Address';

$johns_addr->person( $john );
$ds->save($johns_addr);

my $johns_addr_copy = $ds->objects('Address')->get(1);
isnt $johns_addr_copy, $johns_addr; # not the same objects, assert no identity_map

is $johns_addr_copy->person_id, $john->pk;
isnt $johns_addr_copy->person, $john; # again, asssert no identity map
isnt $johns_addr_copy->person, $jo;

my $matts_addr = Address->new(
    city    => "London",
    person  => Person->new( name => "Matt" ),
);
$ds->save_deep($matts_addr);

isnt $matts_addr->pk, undef;
isnt $matts_addr->person_id, undef;
isnt $matts_addr->person, undef;
$people = $ds->objects('Person')->filter("name = ?", "Matt")->get_objects;
my $matt = shift @$people;
ok defined($matt);

isnt $matt, $matts_addr->person;

# =================================
# start a new session

$ds = MooseX::DataStore->connect($dbh);

my $places;
$places = $ds->objects('Address')->filter('city = ?', 'London')->limit(1)->get_objects;
is scalar @$places, 1;

my $addr = $places->[0];
isnt $addr->person, undef;
isa_ok $addr->person, 'Person';
isnt $addr->person, $matt;

$matt = $addr->person;
$places = $ds->objects('Address')->filter('city = ?', 'London')->limit(1)->get_objects;

$addr = $places->[0];
isnt $addr->person, $matt;

$addr->person( Person->new( name => "James" ) );
$ds->save_deep($addr);

is $addr->person->name, 'James';
isnt $addr->person->id, undef;
isnt $addr->person_id, undef;
my $james = $addr->person;

$addr->person( Person->new( name => 'Paul' ) );
$ds->save($addr->person);
is $addr->person->name, 'Paul';
isnt $addr->person->id, undef;
isnt $addr->person->id, $james->pk;
is $addr->person_id, undef; # since we've not saved this obj
$ds->save($addr);
isnt $addr->person_id, undef; # we've saved already, this should have an id already 

my $paris = Address->new( city => 'Paris', person => $james );
$ds->save_deep($paris, 1);

$places = $ds->objects('Address')->filter({ city => 'Paris', person_id => $james->pk })->get_objects;
$addr = $places->[0];
is $addr->city, 'Paris';
is $addr->person->id, $james->id;

# try querying by person object, not the id
$addr = $ds->objects('Address')->filter({ city => 'Paris', person => $james })->get_first;
is $addr->city, 'Paris';
is $addr->person->id, $james->id;


# reverse foreignkey relationships

$places = $james->addresses->get_objects;
is scalar(@$places), 1;

$addr = $james->addresses->get($paris);
is $addr->pk, $paris->pk;

#$places = $james->addresses->filter("city = ?", "Paris")->get_objects;

ok 1;

=cut

$ds->objects('Address|a', 'Person|p')
   ->where({ 'a.person_id' => 'p.id' })
   ->AND
   ->where({ 'p.name' => { -like => "Bo%" } })
   ->limit(1)
   ->get_objects;

$ds->objects('Address')
   ->count('id')
   ->get_objects;

$ds->objects('Address')
   ->count('id')
   ->group_by('person_id')
   ->get_objects;

=cut


ok 1;

__END__

