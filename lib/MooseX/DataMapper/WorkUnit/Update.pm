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
    foreach my $table (keys %$tuples) {
        foreach my $row (@{$tuples->{$table}}) {
            # remove the primary key from the data hash
            my $pk_column_spec = $t->meta->primary_key->column;
            my $where = { };
            if (ref($pk_column_spec) eq 'ARRAY') {
                foreach my $pk_col (@$pk_column_spec) {
                    # for now, assume column_spec is an array of strings (column names)
                    $where->{$pk_col} = delete($row->{$pk_col});
                }
            }
            else {
                # expect $pk_column_spec as a plain string referring to a single column
                $where->{$pk_column_spec} = delete($row->{$pk_column_spec});
            };
            my ($stmt, @bind) = $self->session->sqlabs->update( $table, $row, $where );
            my $dbixs = $self->session->dbixs;
            $dbixs->query( $stmt, @bind );
            $self->session->query_log_append( [ $stmt, @bind ] );
        }
    }
}

1;

__END__


