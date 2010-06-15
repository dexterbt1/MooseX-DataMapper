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
    my $pk_attr = $t->meta->primary_key;
    my ($stmt, @bind) = $self->session->sqlabs->delete( $table, { ''.$pk_attr->column() => $t->pk } );
    my $dbixs = $self->session->dbixs;
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $dbixs->query( $stmt, @bind );
    $pk_attr->clear_value($t); # undef the primary key, means that the object is not in the db anymore
    $t->datamapper_session( undef );
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $self->session->query_log_append( [ $stmt, @bind ] );
}

1;

__END__
