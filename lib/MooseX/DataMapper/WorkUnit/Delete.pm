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
    my $where;
    my $pk_is_composite = 0;
    if (ref($pk_spec) eq 'ARRAY') { $pk_is_composite = 1; }
    if ($pk_is_composite) {
        $where = $t->pk;
    }
    else {
        $where = { $pk_spec->column() => $t->pk };
    }
    my ($stmt, @bind) = $self->session->sqlabs->delete( $table, $where );
    $self->session->dbixs->query( $stmt, @bind );
    if (not $pk_is_composite) {
        $pk_spec->clear_value($t); # undef the primary key, means that the object is not in the db anymore
    }
    $t->datamapper_session( undef );
    $self->session->query_log_append( [ $stmt, @bind ] );
}

1;

__END__
