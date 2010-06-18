use strict;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'DBIx::Simple';
    use_ok 'MooseX::DataMapper';
}

require 't/lib/CompositeKeys1.pm';

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '','', { RaiseError => 1 } );

$dbh->do( "CREATE TABLE x ( a INTEGER NOT NULL, b INTEGER NOT NULL, c INTEGER NOT NULL, PRIMARY KEY (a, b) )" );

my $session = MooseX::DataMapper->connect($dbh);
$session->debug(1);

my $x1 = X->new( a => 1, b => 1, c => 1 );

# this tests incomplete, or should i say bare minimum metadata in the model, 
# i.e., for class X, all attributes should at least have required => 1.

#dies_ok {       $session->save( X->new( b => 1, c => 1 ) );             } 'save-inc';
#dies_ok {       $session->save( X->new( a => 1, c => 1 ) );             } 'save-inc';
lives_ok {      $session->save( $x1 );                                  } 'save-ok';
like $session->queries->[-1]->[0], qr/INSERT/i, 'x1-insert-ok';
#dies_ok {       $session->save( X->new( a => 1, b => 1, c => 1 ) );     } 'save-dup';
lives_ok {      $session->save( X->new( a => 1, b => 2, c => 1 ) );     } 'save-ok-insert';

lives_ok {      $session->save( $x1 );                                  } 'save-ok-update';
like $session->queries->[-1]->[0], qr/UPDATE/i, 'x1-update-ok';

ok 1;
ok 1;

__END__
