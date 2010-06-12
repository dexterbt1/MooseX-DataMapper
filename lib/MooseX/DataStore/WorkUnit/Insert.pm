package MooseX::DataStore::WorkUnit::Insert;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataStore::WorkUnit';

has 'target' => (
    does            => 'MooseX::DataStore::Meta::Role',
    is              => 'rw',
    required        => 1,
    trigger         => sub {
        my ($self, $v) = @_;
        my $dh = $v->get_data_hash;
        (scalar keys %$dh)
            or croak "Nothing to insert for $v";
    },
);

sub execute {
    my ($self) = @_;
    my $t = $self->target;
    my $table = $t->meta->table;
    my ($stmt, @bind) = $self->datastore->sqlabs->insert( $table, $t->get_data_hash );
    my $dbixs = $self->datastore->dbixs;
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $dbixs->query( $stmt, @bind );
    # automatically assign the primary key field with the last insert id
    my $pk_field = $t->meta->primary_key->name;
    $t->$pk_field( $dbixs->last_insert_id(undef, undef, $table, undef) );
}

1;

__END__

