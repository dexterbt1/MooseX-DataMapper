package MooseX::DataMapper;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;

use MooseX::DataMapper::Session;

sub connect {
    my ($class, $dbh) = @_;
    (blessed($dbh) and $dbh->isa('DBI::db'))
        or croak "connect() expects a valid DBI database handle";
    my $self = MooseX::DataMapper::Session->new( dbh => $dbh );
    return $self;
}


1;

__END__
