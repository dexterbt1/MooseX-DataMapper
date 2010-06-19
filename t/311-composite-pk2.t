use strict;

{
    package Employee;
    use MooseX::DataMapper;
    use Moose -traits => qw/DataMapper::Class/;

    has 'ssn' => (
        traits              => [qw/Persistent/],
        isa                 => 'Str',
        is                  => 'rw',
        column              => 'emp_ssn',
        required            => 1,
    );

    has 'name' => (
        traits              => [qw/Persistent/],
        isa                 => 'Str',
        is                  => 'rw',
        column              => 'emp_name',
        required            => 1,
    );

    __PACKAGE__->meta->datamapper_class_setup(
        -table                  => 'emp',
        -primary_key_type       => 'Composite',
        -primary_key            => [ 'ssn', 'name' ],
    );

}


use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '','', { RaiseError => 1 } );
$dbh->do(q{ 
    CREATE TABLE emp ( emp_ssn VARCHAR NOT NULL, emp_name VARCHAR NOT NULL, PRIMARY KEY (emp_ssn, emp_ssn) )
});

my $session = MooseX::DataMapper->connect($dbh);
$session->debug(1);

my $steve = Employee->new( ssn => '123456', name => 'steve jobs' );
is_deeply $steve->pk, { ssn => '123456', name => 'steve jobs' };

$session->save( $steve );
like $session->queries->[-1]->[0], qr/INSERT/;

$steve->name( 'Steve Jobs' );
$session->save( $steve );
like $session->queries->[-1]->[0], qr/UPDATE/;

my $o = $session->objects('Employee')->get( { ssn => '123456', name => 'Steve Jobs' } );
is $o->name, 'Steve Jobs';
is $o->ssn, '123456';

ok 1;
ok 1;

__END__
