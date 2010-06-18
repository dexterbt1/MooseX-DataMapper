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
    my $table = $t->meta->table;
    my ($stmt, @bind) = $self->session->sqlabs->insert( $table, $t->get_sql_data_hash($self->session) );
    my $dbixs = $self->session->dbixs;
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $dbixs->query( $stmt, @bind );
    # automatically assign the primary key field with the last insert id
    my $pk_field = $t->meta->primary_key->name;
    $t->$pk_field( $dbixs->last_insert_id(undef, undef, $table, undef) );
    $t->datamapper_session( $self->session );
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $self->session->query_log_append( [ $stmt, @bind ] );
}

1;

__END__
