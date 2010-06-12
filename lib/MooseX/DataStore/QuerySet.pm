package MooseX::DataStore::QuerySet;
use strict;
use Moose;
use MooseX::DataStore;
use MooseX::DataStore::QuerySet::Filter;
use MooseX::DataStore::QuerySet::Conjunction;
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
            ($spec->can('does') && $spec->does('MooseX::DataStore::Meta::Role'))
                or croak "$spec is not a valid persistent class";
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

has 'sql_offset' => (
    isa             => 'Int',
    is              => 'rw',
);

has 'filters' => (
    isa             => 'ArrayRef[MooseX::DataStore::QuerySet::Filter|MooseX::DataStore::QuerySet::Conjunction]',
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

sub _get_resultset {
    my ($self) = @_;
    my $ds = $self->datastore;
    $ds->flush;
    my $class = $self->class_spec->[0]; # support single table for now
    my $table = $class->meta->table;
    my $dbixs = $ds->dbixs;
    my $where_stmt = '';
    my @where_bind = ();
    #foreach my $filter (@{$self->filters}) {
    foreach my $item (@{$self->filters}) {
        if ($item->isa('MooseX::DataStore::QuerySet::Conjunction')) {
            $where_stmt .= ' '.$item->term.' ';
            next;
        }
        my $filter = $item;
        $where_stmt .= $filter->sql_stmt;
        push @where_bind, @{$filter->bind_params};
    }
    my ($select_stmt) = $ds->sqlabs->select( $table, $self->_get_columns, $where_stmt, undef, $self->sql_limit, $self->sql_offset );
    my $rs;
    eval {
        $rs = $dbixs->query($select_stmt, @where_bind);
    };
    if ($@) {
        croak "Failed SQL statement:\n\t$select_stmt".join("\n\t",@where_bind);
    }
    print STDERR $select_stmt,"\n\t",join("\n\t",@where_bind),"\n";
    return $rs;
}


sub _new_object {
    my ($self, $class, $row) = @_;
    my $pk_rowfield = $class->meta->primary_key->column;
    my $pk = $row->{$pk_rowfield};
    my $o;
    {
        my $args = {};
        foreach my $col (keys %$row) {
            my $attr_name = $class->meta->column_to_attribute->{$col};
            next if (not defined $attr_name); # ignore non-member columns
            my $row_val = $row->{$col};
            next if (not defined $row_val);
            $args->{$attr_name} = $row->{$col};
        }
        $o = $class->new(%$args);
        $o->datastore( $self->datastore );
    }
    return $o;
}


sub _apply_conjunction {
    my ($self, $term) = @_;
    my $len = scalar @{$self->filters};
    ($len > 0)
        or croak "Conjunction cannot be applied to an empty QuerySet";
    my $head = $self->filters->[-1];
    ($head->isa('MooseX::DataStore::QuerySet::Filter'))
        or croak "QuerySet Conjunction should only be applied after a Filter";
    push @{$self->filters}, MooseX::DataStore::QuerySet::Conjunction->new( term => $term );
}


# ===============
# public api
# ===============


# queryset methods that can be chained


sub filter {
    my ($self, $where_clause, @bind) = @_;
    my $clause;
    my $bind_params = \@bind;
    if (ref($where_clause) eq 'HASH') {
        ($clause, my @b) = $self->datastore->sqlabs->where($where_clause);
        $clause =~ s[^\s*WHERE\s*][];
        $bind_params = \@b;
    }
    else {
        $clause = '('.$where_clause.')';
    }
    push @{$self->filters}, MooseX::DataStore::QuerySet::Filter->new( 
        queryset    => $self,
        clause      => $clause,
        bind_params => $bind_params,
    );
    return $self;
}


sub or {
    my ($self) = @_;
    $self->_apply_conjunction( 'OR' );
    return $self;
}


sub and {
    my ($self) = @_;
    $self->_apply_conjunction( 'AND' );
    return $self;
}


sub limit {
    my ($self, $limit) = @_;
    # TODO: sql-abstract
    $self->sql_limit($limit);
    return $self;
}


sub offset {
    my ($self, $offset) = @_;
    $self->sql_offset($offset);
    return $self;
}


# queryset methods that return row(s)


sub first_object {
    my ($self) = @_;
    my $class = $self->class_spec->[0]; # support single table for now
    if (not defined $self->sql_offset) {
        # optimize a bit
        $self->limit(1);
    }
    my $rs = $self->_get_resultset;
    my $row = $rs->hash;
    return $self->_new_object( $class, $row );
}


sub get {
    my ($self, $pk) = @_;
    my $class = $self->class_spec->[0]; # support single table for now
    my $pk_field = $class->meta->primary_key->name;
    $self->filter({$pk_field => $pk})->limit(1);
    my $rs = $self->_get_resultset;
    my $row = $rs->hash;
    return $self->_new_object( $class, $row );
}


sub as_objects {
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
