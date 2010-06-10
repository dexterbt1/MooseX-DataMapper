package MooseX::DataStore::QuerySet;
use strict;
use Moose;
use MooseX::DataStore;
use Carp;

has 'datastore' => (
    isa             => 'MooseX::DataStore',
    is              => 'rw',
    required        => 1,
);

has 'class_spec' => (
    isa             => 'ArrayRef',
    is              => 'rw',
    trigger         => sub {
        my ($self, $v) = @_;
        (scalar @$v > 0)
            or croak "Invalid query class_spec";
        foreach my $spec (@$v) {
            ($spec->does('MooseX::DataStore::Class'))
                or croak "Class $spec is not a valid persistent class";
        }
    },
    required        => 1,
);

has 'columns' => (
    isa             => 'ArrayRef',
    is              => 'rw',
    lazy            => 1,
    default         => sub { [] },
);


sub get_columns {
    my ($self) = @_;
    if (scalar @{$self->columns} == 0) {
    }
    return '*';
}

# ===============

sub as_array {
    my ($self) = @_;
    my $ds = $self->datastore;
    my $class = $self->class_spec->[0]; # support single table for now
    my $table = $class->meta->table;
    my $dbixs = $ds->dbixs;
    my ($stmt, @bind) = $ds->sqlabs->select( $table, $self->get_columns, undef );
    $ds->flush; 
    my $rs = $dbixs->query($stmt, @bind);
    my @result = ();
    while (my $row = $rs->hash) {
        my $o = $self->new_object( $class, $row );
        push @result, $o;
    }
    return \@result;
}

sub new_object {
    my ($self, $class, $row) = @_;
    my $pk_rowfield = $class->meta->primary_key->column;
    my $pk = $row->{$pk_rowfield};
    my $o = $self->datastore->get_idmap_cached( $class, $pk );
    {
        my $args = {};
        foreach my $col (keys %$row) {
            my $attr_name = $class->meta->column_to_attribute->{$col};
            my $row_val = $row->{$col};
            next if (not defined $row_val);
            if (not $o) {
                $args->{$attr_name} = $row->{$col};
            }
            else {
                $o->$attr_name($row_val); # coerce?
            }
        }
        if (not $o) {
            $o = $class->new(%$args);
            $self->datastore->set_idmap_cached( $class, $pk, $o );
        }
    }
    return $o;
}







1;

__END__
