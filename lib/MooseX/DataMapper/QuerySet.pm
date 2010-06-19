package MooseX::DataMapper::QuerySet;
use strict;
use Moose;
use MooseX::DataMapper;
use MooseX::DataMapper::QuerySet::Filter;
use MooseX::DataMapper::QuerySet::LogicalOperator;
use Carp;
use Scalar::Util qw/blessed/;

has 'session' => (
    isa             => 'MooseX::DataMapper::Session',
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
            ($spec->can('does') && $spec->does('MooseX::DataMapper::Meta::Role'))
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

has 'static_filters' => (
    isa             => 'ArrayRef[MooseX::DataMapper::QuerySet::Filter]',
    is              => 'rw',
    lazy            => 1,
    default         => sub { [] },
);

has 'filters' => (
    isa             => 'ArrayRef[MooseX::DataMapper::QuerySet::Filter|MooseX::DataMapper::QuerySet::LogicalOperator]',
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
    my $ds = $self->session;
    my $class = $self->class_spec->[0]; # support single table for now
    my $table = $class->meta->table;
    my $dbixs = $ds->dbixs;
    my $where_stmt = '';
    my @where_bind = ();
    {
        my $count = 0;
        foreach my $filter (@{$self->static_filters}) {
            if ($count>0) { $where_stmt .= ' AND '; } # all static filters are joined by AND
            $where_stmt .= $filter->sql_stmt;
            push @where_bind, @{$filter->bind_params};
            $count++;
        }
    }
    if ( (scalar(@{$self->filters}) > 0) && (scalar(@{$self->static_filters}) > 0) ) {
        $where_stmt .= ' AND ';
    }
    foreach my $item (@{$self->filters}) {
        
        if ($item->isa('MooseX::DataMapper::QuerySet::LogicalOperator')) {
            $where_stmt .= ' '.$item->term.' ';
            next;
        }
        my $filter = $item;
        $where_stmt .= $filter->sql_stmt;
        push @where_bind, @{$filter->bind_params};
    }
    my ($select_stmt) = $ds->sqlabs->select( $table, $self->_get_columns, $where_stmt, undef, $self->sql_limit, $self->sql_offset );
    my $rs;
    $ds->query_log_append( [ $select_stmt, \@where_bind ] );
    eval {
        $rs = $dbixs->query($select_stmt, @where_bind);
    };
    if ($@) {
        croak "Failed SQL statement:\n\t$select_stmt\n\t".join("\n\t",@where_bind)."\n";
    }
    return $rs;
}


sub _new_object {
    # FIXME: perhaps we can refactor this since it belongs to some other class like an ObjectBuilder or similar (?)
    my ($self, $class, $row) = @_;
    # FIXME: caller methods, those returning objects ideally should throw an Exception undef row scenario, e.g. DoesNotExist exception
    return if (not(defined $row));
    my $o;
    my $driver_name = $self->session->dbh->get_info(17);
    {
        my $args = {};
        foreach my $col (keys %$row) {
            my $attr_name = $class->meta->column_to_attribute->{$col};
            next if (not defined $attr_name); # ignore non-member columns
            my $attr = $class->meta->get_attribute($attr_name);
            my $row_val = $row->{$col};
            next if (not defined $row_val);
            $args->{$attr_name} = $row->{$col};
            if ($attr->does('WithColumnHandler')) {
                $args->{$attr_name} = $attr->from_db->( $row->{$col}, $driver_name );
            }
        }
        $o = $class->meta->new_object(%$args);
        $o->datamapper_session( $self->session );
    }
    return $o;
}


sub _apply_logical_operator {
    my ($self, $term) = @_;
    my $len = scalar @{$self->filters};
    ($len > 0)
        or croak "Logical operator cannot be applied to an empty QuerySet";
    my $head = $self->filters->[-1];
    ($head->isa('MooseX::DataMapper::QuerySet::Filter'))
        or croak "QuerySet logical operator should only be applied after a Filter";
    push @{$self->filters}, MooseX::DataMapper::QuerySet::LogicalOperator->new( term => $term );
}


# ===============
# public api
# ===============


# mutator methods


# queryset methods that can be chained


sub _add_filter {
    my ($self, $collection, $where_clause, @bind) = @_;
    my $clause;
    my $bind_params = \@bind;
    if (ref($where_clause) eq 'HASH') {
        ($clause, my @b) = $self->session->sqlabs->where($where_clause);
        $clause =~ s[^\s*WHERE\s*][];
        $bind_params = \@b;
    }
    else {
        $clause = '('.$where_clause.')';
    }
    push @{$self->$collection}, MooseX::DataMapper::QuerySet::Filter->new( 
        queryset    => $self,
        clause      => $clause,
        bind_params => $bind_params,
    );
    return $self;
}


sub static_filter {
    my $self = shift @_;
    return $self->_add_filter( 'static_filters', @_ );
}

sub filter {
    my $self = shift @_;
    return $self->_add_filter( 'filters', @_ );
}


sub or {
    my ($self) = @_;
    $self->_apply_logical_operator( 'OR' );
    return $self;
}


sub and {
    my ($self) = @_;
    $self->_apply_logical_operator( 'AND' );
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


# queryset methods that return objects


sub first {
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
    my ($self, $o) = @_;
    # accept either an object or a primary_key-style (can be a scalar OR a hashref) value

    my $class = $self->class_spec->[0]; # support single table for now
    my $class_pk = $class->meta->primary_key;

    my $where = $class_pk->get_column_condition( $o );

    $self->static_filter($where)->limit(1);
    my $rs = $self->_get_resultset;
    my $row = $rs->hash;
    return $self->_new_object( $class, $row );
}


sub all {
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


package MooseX::DataMapper::AssociationQuerySet;
use strict;
use Moose;

extends 'MooseX::DataMapper::QuerySet';

has 'parent_object' => (
    does                => 'MooseX::DataMapper::Meta::Role',
    is                  => 'rw',
    required            => 1,
);

has 'fk_attr' => (
    isa                 => 'Moose::Meta::Attribute',
    is                  => 'rw',
    required            => 1,
);

has 'ref_from_attr' => (
    isa                 => 'Moose::Meta::Attribute',
    is                  => 'rw',
    required            => 1,
);

has 'ref_to_attr' => (
    isa                 => 'Moose::Meta::Attribute',
    is                  => 'rw',
    required            => 1,
);

sub save {
    my ($self, $i) = @_;
    $self->fk_attr->set_value( $i, $self->parent_object );
    $self->session->save( $i );
}


sub delete {
    my ($self, $i) = @_;
    $self->session->delete( $i );
}



1;

__END__
