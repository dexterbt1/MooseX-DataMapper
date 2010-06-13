package MooseX::DataMapper::WorkUnit;
use strict;
use Moose;
use Carp;

has 'session' => (
    isa             => 'MooseX::DataMapper::Session',
    is              => 'rw',
);

sub execute {
    croak "Unimplemented!";
}


1;

__END__
