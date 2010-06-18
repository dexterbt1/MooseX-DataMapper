use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}


require 't/lib/MetaOverride.pm';
my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '','', { RaiseError => 1 } );

$dbh->do( "CREATE TABLE my_x (id INTEGER PRIMARY KEY AUTOINCREMENT, x_b INTEGER, c INTEGER)" );

lives_ok {
    X->meta->table('my_x');
} 'set table';

dies_ok {
    X->meta->map_attr_column( undef, 'x_b' );
} 'empty remap';

lives_ok {
    X->meta->map_attr_column( b => 'x_b' );
} 'remap';

is X->meta->get_attribute('b')->column, 'x_b';

my $x = X->new( b => 2, c => 3 ); 

my $session = MooseX::DataMapper->connect($dbh);
$session->debug(1);

lives_ok {
    $session->save( $x );
} 'save';

isnt $x->a, undef;

dies_ok {
    X->meta->map_attr_column( b => 'c' );
} 'dup column';

is X->meta->get_attribute('b')->column, 'x_b';


ok 1;

__END__

