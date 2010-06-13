package MooseX::DataMapper::WorkUnit::CodeHook;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataMapper::WorkUnit';

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
