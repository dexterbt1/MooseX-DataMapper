package MooseX::DataMapper::WorkUnit::Insert;
use strict;
use Moose;
use Carp;
use DBIx::Simple;
use Data::Dumper;

extends 'MooseX::DataMapper::WorkUnit';

has 'target' => (
    does            => 'MooseX::DataMapper::Meta::Role',
    is              => 'rw',
    required        => 1,
);

sub execute {
    my ($self) = @_;
    my $t = $self->target;
    my $tuples = $t->meta->get_tuples( $t, $self->session, $t->meta->table );
    foreach my $table (keys %$tuples) {
        foreach my $row (@{$tuples->{$table}}) {
            my ($stmt, @bind) = $self->session->sqlabs->insert( $table, $row );
            my $dbixs = $self->session->dbixs;
            $dbixs->query( $stmt, @bind );
            # automatically assign the primary key field with the last insert id
            my $pk_spec = $t->meta->primary_key;
            if (ref($pk_spec) eq 'ARRAY') {
                # nop, do nothing
            }
            else {
                $pk_spec->set_value( $t, $dbixs->last_insert_id(undef, undef, $table, undef) );
            }
            $t->datamapper_session( $self->session );
            $self->session->query_log_append( [ $stmt, @bind ] );
        }
    }
}

1;

__END__
