use strict;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

require 't/lib/CompositeKeys1.pm';

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '','', { RaiseError => 1 } );

$dbh->do( "CREATE TABLE x ( z_a INTEGER NOT NULL, z_b INTEGER NOT NULL, z_c INTEGER NOT NULL, PRIMARY KEY (z_a, z_b) )" );

my $session = MooseX::DataMapper->connect($dbh);
$session->debug(1);

my $x1 = X->new( a => 1, b => 1, c => 1 );

# this tests incomplete, or should i say bare minimum metadata in the model, 
# i.e., for class X, all attributes should at least have required => 1.

lives_ok {      $session->save( $x1 );                                  } 'save-ok';
is scalar @{$session->queries}, 1;
like $session->queries->[-1]->[0], qr/INSERT/i, 'x1-insert-ok';

lives_ok {      $session->save( X->new( a => 1, b => 2, c => 1 ) );     } 'save-ok-insert';
is scalar @{$session->queries}, 2;
like $session->queries->[-1]->[0], qr/INSERT/i, 'x1-insert-ok';

$x1->c(3);
lives_ok {      $session->save( $x1 );                                  } 'save-ok-update';
is scalar @{$session->queries}, 3;
like $session->queries->[-1]->[0], qr/UPDATE/i, 'x1-update-ok';

is scalar @{$session->objects('X')->all}, 2;

lives_ok {      $session->delete( $x1 );                                } 'del-ok';

is scalar @{$session->objects('X')->all}, 1;

my $x1_copy;
dies_ok {
    $x1_copy = $session->objects('X')->get( { a => 1, y => 2 } );
} 'unknown column y';

lives_ok {
    $x1_copy = $session->objects('X')->get( { a => 1, b => 2 } );
}  'get by hash pk';
is_deeply $x1_copy->pk, { a => 1, b => 2 };
is $x1_copy->a, 1;
is $x1_copy->b, 2;
is $x1_copy->c, 1;

my $x1_copy2 = $session->objects('X')->get( $x1_copy->pk );
is_deeply $x1_copy2->pk, $x1_copy->pk;

$session->save( X->new( a => 5, b => 6, c => 7 ) );
$session->save( X->new( a => 8, b => 9, c => 10 ) );

my $xs = $session->objects('X')->filter('b > ?', 5)->all;
is scalar @$xs, 2;



ok 1;
ok 1;

__END__
