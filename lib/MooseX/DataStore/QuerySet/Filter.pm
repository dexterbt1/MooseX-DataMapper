package MooseX::DataStore::QuerySet::Filter;
use strict;
use Moose;
use Carp;

has 'queryset' => (
    isa             => 'MooseX::DataStore::QuerySet',
    is              => 'rw',
    required        => 1,
);

has 'clause' => (
    isa             => 'Str',
    is              => 'rw',
    required        => 1,
);

has 'bind_params' => (
    isa             => 'ArrayRef',
    is              => 'rw',
    required        => 1,
);

has 'sql_stmt' => (
    isa             => 'Str',
    is              => 'rw',
);


sub BUILD {
    my ($self) = @_;
    my $class = $self->queryset->class_spec->[0]; # single table for now
    my $stmt = $self->clause;
    foreach my $attr (@{$class->meta->persistent_attributes}) {
        my $attr_name = $attr->name;
        my $col = $attr->column;
        $stmt =~ s[\b$attr_name\b][$col]g;
    }
    $self->sql_stmt( $stmt );
}


sub get_sql_stmt_bind {
    my ($self) = @_;
    return ($self->sql_stmt, @{$self->bind_params});
}


1;

__END__

