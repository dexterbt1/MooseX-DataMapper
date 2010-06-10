package MooseX::DataStore::QuerySet::Filter;
use strict;
use Moose;
use Carp;

has 'queryset' => (
    isa             => 'MooseX::DataStore::QuerySet',
    is              => 'rw',
    required        => 1,
);

has 'spec' => (
    isa             => 'HashRef',
    is              => 'rw',
    required        => 1,
);

has 'compiled_spec' => (
    isa             => 'HashRef',
    is              => 'rw',
);


sub BUILD {
    my ($self) = @_;
    my $spec = $self->spec;
    my $cspec = { };
    my $class = $self->queryset->class_spec->[0]; # single table for now
    foreach my $attr_name_spec (keys %$spec) {
        my $attr_name = $attr_name_spec;
        my $col = $class->meta->attribute_to_column->{$attr_name};
        (defined $col)
            or croak "Unable to resolve column for attribute ($attr_name)";
        $cspec->{$col} = $spec->{$attr_name};
    }
    $self->compiled_spec( $cspec );
}


sub get_sql_stmt_bind {
    my ($self) = @_;
    my ($stmt, @bind) = $self->queryset->datastore->sqlabs->where( $self->compiled_spec );
    $stmt =~ s[^\s*WHERE\s*][]i;
    return ($stmt, @bind);
}


1;

__END__

