package MooseX::DataMapper::WorkUnit::Update;
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
    my $tuples = $t->meta->get_tuples( $t, $self->session, $t->meta->table );
    my $pk_spec = $t->meta->primary_key;
    foreach my $table (keys %$tuples) {
        foreach my $row (@{$tuples->{$table}}) {
            # remove the primary key from the data hash
            my $where = $pk_spec->get_column_condition( $t );
            foreach my $pk_col (%$where) {
                delete $row->{$pk_col};
            }
            my $dirty_pk = $pk_spec->is_dirty($t);
            if ($dirty_pk) {
                my $dirty_pk_cols = $pk_spec->get_dirty_columns($t);
                $row = { %$row, %$dirty_pk_cols };
            }
            my ($stmt, @bind) = $self->session->sqlabs->update( $table, $row, $where );
            my $dbixs = $self->session->dbixs;
            $self->session->query_log_append( [ $stmt, @bind ] );
            my $rs = $dbixs->query( $stmt, @bind );
            if ($dirty_pk) {
                # TODO: assume this runs only after successful query (RaiseError=1)
                $pk_spec->cleanup_dirty($t); #
            }
        }
    }
}

1;

__END__


