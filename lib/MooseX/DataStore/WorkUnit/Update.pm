package MooseX::DataStore::WorkUnit::Update;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataStore::WorkUnit';

has 'target' => (
    does            => 'MooseX::DataStore::Class',
    is              => 'rw',
);

sub execute {
    my ($self) = @_;
    my $t = $self->target;
    my $table = $t->meta->table;
    my ($stmt, @bind) = $self->datastore->sqlabs->update( $table, $t->get_data_hash );
    my $dbixs = $self->datastore->dbixs;
    $dbixs->query( $stmt, @bind );
    $self->datastore->set_idmap_cached( $t->meta->name, $t->pk, $t );
}

1;

__END__


