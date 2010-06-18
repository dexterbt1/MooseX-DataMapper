use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

require 't/lib/CompositeKeys1.pm';

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '','', { RaiseError => 1 } );

$dbh->do( "CREATE TABLE x ( id INTEGER PRIMARY KEY AUTOINCREMENT, a INTEGER, b INTEGER, c INTEGER)" );

#my $x = X->new( b => 2, c => 3 ); 

#my $session = MooseX::DataMapper->connect($dbh);
#$session->debug(1);

ok 1;
ok 1;

__END__
