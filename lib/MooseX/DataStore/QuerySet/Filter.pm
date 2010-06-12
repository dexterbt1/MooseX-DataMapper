package MooseX::DataStore::QuerySet::Filter;
use strict;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;

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
    foreach my $attr (@{$class->meta->foreignkey_attributes}) {
        my $attr_name = $attr->name;
        next if (not($stmt =~ /\b$attr_name\b/)); # skip if foreignkey attr name is not in the statement
        my $from_class = $class;
        my $from_attr = $class->meta->get_attribute( $attr->ref_from );
        my $from_col = $from_attr->column;
        my $to_attr = $attr->ref_to_attr;
        my $to_col = $to_attr->column;
        my ($to_class, $to_attr_name) = ($to_attr->associated_class->name, $to_attr->name);
        $stmt =~ s[\b$attr_name\b][$from_col]g;
        for (my $bp_i=0; $bp_i < scalar(@{$self->bind_params}); $bp_i++) {
            my $bindp = $self->bind_params->[$bp_i];
            if (blessed($bindp) and $bindp->can($to_attr_name)) {
                $self->bind_params->[$bp_i] = $bindp->$to_attr_name;
            }
        }
    }
    $self->sql_stmt( $stmt );
}


sub get_sql_stmt_bind {
    my ($self) = @_;
    return ($self->sql_stmt, @{$self->bind_params});
}


1;

__END__

