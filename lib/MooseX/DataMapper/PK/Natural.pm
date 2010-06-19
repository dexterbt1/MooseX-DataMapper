package MooseX::DataMapper::PK::Natural;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;
with 'MooseX::DataMapper::PK';

has 'source_meta' => (
    isa         => 'Moose::Meta::Class',
    is          => 'rw',
    required    => 1,
);

has 'attr' => (
    does        => 'MooseX::DataMapper::Meta::Attribute::Trait::Persistent',
    is          => 'rw',
    required    => 1,
    trigger     => sub {
        my ($self, $v) = @_;
        $v->is_required
            or die "Attribute mapped to a Simple Primary Key should be set to required=1";
    },
);


sub BUILDARGS {
    my ($self, $source_meta, $spec) = @_;
    ($source_meta->has_attribute($spec))
        or croak "Unable to resolve attribute $spec";
    return { 
        attr        => $source_meta->get_attribute($spec),
        source_meta => $source_meta,
    };
}

# inside-out management of dirty natural keys
my $dirty_natkeys = { };

sub BUILD {
    my ($self) = @_;
    my $attr = $self->attr;
    my $method = $attr->writer || $attr->accessor || $attr->name;
    $self->source_meta->add_before_method_modifier( $method, sub {
        my $obj = shift @_;
        if (scalar @_ == 1) {
            # setter called, we need to save the old value,
            # this old value will later be used as the dirty column value
            # ... this also mark object as dirty
            $dirty_natkeys->{"$obj"} = $attr->get_value($obj);
        }
    });
}

sub is_serial { 0 }

sub set_serial { die "Unimplemented" }
sub clear_serial { die "Unimplemented" }

sub get_instance_value {
    my ($self, $instance) = @_;
    return $self->attr->get_value( $instance );
}


sub is_dirty { 
    my ($self, $obj) = @_;
    (exists $dirty_natkeys->{"$obj"}) ? 1 : 0;
}

sub cleanup_dirty {
    my ($self, $obj) = @_;
    delete $dirty_natkeys->{"$obj"};
}

sub get_column_condition {
    my ($self, $obj) = @_;
    my $pk_val = $obj;
    if (blessed $obj) {
        $pk_val = (exists $dirty_natkeys->{"$obj"}) 
                ? $dirty_natkeys->{"$obj"}
                : $self->attr->get_value($obj);
    }
    return { $self->attr->column() => $pk_val };
}

sub get_dirty_columns {
    my ($self, $obj ) = @_;
    my $new_value = $obj; # assume by default that the obj is the pk serial value
    if (blessed $obj) {
        # otherwise, this is an object, retrieve the actual serial value from the object
        $new_value = $self->attr->get_value($obj);
    }
    return { $self->attr->column()  =>  $new_value  };
}



1;

__END__


