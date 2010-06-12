package MooseX::DataStore::WorkUnit::Update;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataStore::WorkUnit';

has 'target' => (
    does            => 'MooseX::DataStore::Meta::Role',
    is              => 'rw',
);

sub execute {
    my ($self) = @_;
    my $t = $self->target;
    my $table = $t->meta->table;
    my $data = $t->get_data_hash;
    # remove the primary key from the data hash
    my $pk_column = $t->meta->primary_key->column;
    my $where = { 
        $pk_column => delete($data->{$pk_column}),
    };
    my ($stmt, @bind) = $self->datastore->sqlabs->update( $table, $data, $where );
    my $dbixs = $self->datastore->dbixs;
    $dbixs->query( $stmt, @bind );
    ##print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
}

1;

__END__


