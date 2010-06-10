package MooseX::DataStore::QuerySet;
use strict;
use Moose;
use MooseX::DataStore;
use MooseX::DataStore::QuerySet::Filter;
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

has 'sql_limit' => (
    isa             => 'Int',
    is              => 'rw',
);

has 'filters' => (
    isa             => 'ArrayRef[MooseX::DataStore::QuerySet::Filter]',
    is              => 'rw',
    lazy            => 1,
    default         => sub { [] },
);

# ==============


sub _get_columns {
    my ($self) = @_;
    if (scalar @{$self->columns} == 0) {
    }
    return '*';
}

sub _get_filters {
    my ($self) = @_;
    if (scalar @{$self->filters} > 0) {
        my $filter = shift @{$self->filters};
        return $filter->compiled_spec;
    }
    return {};
}

sub _get_resultset {
    my ($self) = @_;
    my $ds = $self->datastore;
    $ds->flush;
    my $class = $self->class_spec->[0]; # support single table for now
    my $table = $class->meta->table;
    my $dbixs = $ds->dbixs;
    my ($stmt, @bind) = $ds->sqlabs->select( $table, $self->_get_columns, $self->_get_filters, undef, $self->sql_limit );
    my $rs = $dbixs->query($stmt, @bind);
    return $rs;
}


sub _new_object {
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


# ===============
# public api
# ===============


# queryset methods that can be chained


sub filter {
    my ($self, $filter_spec) = @_;
    push @{$self->filters}, MooseX::DataStore::QuerySet::Filter->new( 
        queryset    => $self,
        spec        => $filter_spec 
    );
    return $self;
}


sub limit {
    my ($self, $limit) = @_;
    $self->sql_limit($limit);
    return $self;
}


# queryset methods that return rows

sub get {
    my ($self, $pk) = @_;
    my $class = $self->class_spec->[0]; # support single table for now
    my $pk_field = $class->meta->primary_key->name;
    $self->filter({ $pk_field => $pk })->limit(1);
    my $rs = $self->_get_resultset;
    my $row = $rs->hash;
    return $self->_new_object( $class, $row );
}


sub rows {
    my ($self) = @_;
    my $class = $self->class_spec->[0]; # support single table for now
    my $rs = $self->_get_resultset;
    my @result = ();
    while (my $row = $rs->hash) {
        my $o = $self->_new_object( $class, $row );
        push @result, $o;
    }
    return \@result;
}




1;

__END__
