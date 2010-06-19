package MooseX::DataMapper::WorkUnit::Delete;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataMapper::WorkUnit';

has 'target' => (
    does            => 'MooseX::DataMapper::Meta::Role',
    is              => 'rw',
);


sub execute {
    my ($self) = @_;
    my $t = $self->target;
    my $table = $t->meta->table;
    my $pk_spec = $t->meta->primary_key;
    my $where = $pk_spec->get_column_condition( $t );
    my ($stmt, @bind) = $self->session->sqlabs->delete( $table, $where );
    $self->session->query_log_append( [ $stmt, @bind ] );
    $self->session->dbixs->query( $stmt, @bind );
    if ($pk_spec->is_serial) {
        $pk_spec->clear_serial($t); 
    }
    $t->datamapper_session( undef );
}

1;

__END__
