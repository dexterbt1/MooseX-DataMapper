use strict;
use warnings;

{
    package Person;
    use strict;
    use MooseX::DataMapper;
    use Moose -traits => qw/DataMapper::Class/;

    has 'name' => (
        traits              => [qw/Persistent/],
        isa                 => 'Str',
        is                  => 'rw',
        column              => 'the_name',
        writer              => 'set_name',
        required            => 1,
    );

    __PACKAGE__->meta->datamapper_class_setup(
        -table              => 'person',
        -primary_key_type   => 'Natural',
        -primary_key        => 'name',
    );
}

# --------------- in database operations
package main;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

isa_ok( Person->meta->primary_key, 'MooseX::DataMapper::PK::Natural' );


my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1, PrintError => 0 });
$dbh->do(<<"EOT");
    CREATE TABLE person (the_name VARCHAR, PRIMARY KEY (the_name));
EOT

my $ds = MooseX::DataMapper->connect($dbh);
$ds->debug(1);

my $p;

lives_ok {
    $p = Person->new( name => 'John' );
    $ds->save($p);
} 'insert';

like $ds->queries->[-1]->[0], qr/INSERT/;
is scalar @{$ds->objects('Person')->all}, 1;



dies_ok {
    my $p2 = Person->new( name => 'John' );
    $ds->save($p2);
    sleep 1;
} 'insert dup';
like $ds->queries->[-1]->[0], qr/INSERT/;



lives_ok {
    $p->set_name( 'John Doe' );
    $ds->save($p);
} 'insert dup';
like $ds->queries->[-1]->[0], qr/UPDATE/;

is scalar @{$ds->objects('Person')->all}, 1; # still one record

# we're making sure it's the correct updated person

$p = $ds->objects('Person')->get( 'John Doe' ); # single val
is $p->name, 'John Doe'; 

# we're making sure it's the correct updated person
$p = $ds->objects('Person')->get( $p ); # obj
is $p->name, 'John Doe'; 

# we're making sure it's the correct updated person
$p = $ds->objects('Person')->first;
is $p->name, 'John Doe'; 

ok 1;
ok 1;


__END__

