package MooseX::DataMapper;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;

our $VERSION = 0.01;

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

=head1 NAME

MooseX::DataMapper - An object-relational mapper for persisting / querying Moose-based objects in SQL relational databases

=head1 SEE ALSO

L<http://github.com/dexterbt1/MooseX-DataMapper>

=head1 AUTHOR

Dexter Tad-y, <dexterbt1@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dexter Tad-y

