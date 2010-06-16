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
    my $table = $t->meta->table;
    my $data = $t->get_sql_data_hash( $self->session );
    # remove the primary key from the data hash
    my $pk_column = $t->meta->primary_key->column;
    my $where = { 
        $pk_column => delete($data->{$pk_column}),
    };
    my ($stmt, @bind) = $self->session->sqlabs->update( $table, $data, $where );
    my $dbixs = $self->session->dbixs;
    $dbixs->query( $stmt, @bind );
    #print STDERR $stmt,"\n\t",join("\n\t",@bind),"\n";
    $self->session->query_log_append( [ $stmt, @bind ] );
}

1;

__END__


