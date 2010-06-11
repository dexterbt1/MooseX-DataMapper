package MooseX::DataStore::WorkUnit::CodeHook;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataStore::WorkUnit';

has 'hook' => (
    isa             => 'CodeRef',
    is              => 'rw',
    required        => 1,
);

sub execute {
    my ($self) = @_;
    $self->hook->();
}

1;

__END__
