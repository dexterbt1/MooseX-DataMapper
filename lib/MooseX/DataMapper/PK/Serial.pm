package MooseX::DataMapper::PK::Serial;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;
with 'MooseX::DataMapper::PK';


has 'attr' => (
    does        => 'MooseX::DataMapper::Meta::Attribute::Trait::Persistent',
    is          => 'rw',
    required    => 1,
);


sub BUILDARGS {
    my ($self, $source_meta, $spec) = @_;
    ($source_meta->has_attribute($spec))
        or croak "Unable to resolve attribute $spec";
    return { attr => $source_meta->get_attribute($spec) };
}

sub is_serial { 1 }

sub set_serial {
    my ($self, $obj, $new_serial_val) = @_;
    $self->attr->set_value( $obj, $new_serial_val );
}

sub clear_serial {
    my ($self, $obj ) = @_;
    $self->attr->clear_value( $obj );
}

sub get_column_condition {
    my ($self, $obj ) = @_;
    my $pk_value = $obj; # assume by default that the obj is the pk serial value
    if (blessed $obj) {
        # otherwise, this is an object, retrieve the actual serial value from the object
        $pk_value = $self->attr->get_value($obj);
    }
    return { $self->attr->column()  =>  $pk_value  };
}

sub get_instance_value {
    my ($self, $instance) = @_;
    return $self->attr->get_value( $instance );
}

# no dirty management needed

sub is_dirty { 0 }

sub cleanup_dirty { 1 }

sub get_dirty_columns {
    return { }; # none
}


1;

__END__

