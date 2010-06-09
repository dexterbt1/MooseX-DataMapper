package MooseX::DataStore::WorkUnit::Insert;
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
    my ($stmt, @bind) = $self->datastore->sqlabs->insert( $table, $t->get_data_hash );
    my $dbixs = $self->datastore->dbixs;
    $dbixs->query( $stmt, @bind );
    # automatically assign the primary key field with the last insert id
    my $pk_field = $t->meta->primary_key->name;
    $t->$pk_field( $dbixs->last_insert_id(undef, undef, $table, undef) );
    $self->datastore->add( $t ); # add again, ensure this is cached for future requests
}

1;

__END__

