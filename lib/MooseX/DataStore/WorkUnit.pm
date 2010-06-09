package MooseX::DataStore::WorkUnit;
use strict;
use Moose;
use Carp;

has 'datastore' => (
    isa             => 'MooseX::DataStore',
    is              => 'rw',
);

sub execute {
    croak "Unimplemented!";
}


1;

__END__
