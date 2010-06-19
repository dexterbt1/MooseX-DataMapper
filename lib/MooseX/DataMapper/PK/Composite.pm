package MooseX::DataMapper::PK::Composite;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;

with 'MooseX::DataMapper::PK';

has 'attr_of' => (
    isa         => 'HashRef',
    is          => 'rw',
);

has 'attrs' => (
    does        => 'ArrayRef[MooseX::DataMapper::Meta::Attribute::Trait::Persistent]',
    is          => 'rw',
    required    => 1,
);


sub BUILD {
    my ($self) = @_;
    $self->attr_of( { map { $_->name() => $_ } @{$self->attrs} } );
}


sub is_serial { 0 }
sub set_serial { croak "Unimplemented"; }
sub clear_serial { croak "Unimplemented"; }


sub get_column_condition {
    my ($self, $obj ) = @_;
    my $out = { };
    if (blessed $obj) {
        # otherwise, this is an object, retrieve the actual serial value from the object
        foreach my $pk_attr (@{$self->attrs}) {
            my $key = $pk_attr->column;
            my $value = $pk_attr->get_value($obj);
            $out->{$key} = $value;
        }
    }
    else {
        # assume a HASHREF
        (ref($obj) eq 'HASH')
            or croak "Unsupported column condition format for composite keys";
        my $user_params = $obj;
        # validate hashref, convert attributes to columns
        foreach my $user_attr_name (keys %$user_params) {
            (exists $self->attr_of->{$user_attr_name})
                or croak "Unknown attribute $user_attr_name used in composite condition";
            my $attr = $self->attr_of->{$user_attr_name};
            $out->{$attr->column} = $user_params->{$user_attr_name};
        }
    }
    return $out;
}


sub get_instance_value {
    my ($self, $instance) = @_;
    my $out = { };
    foreach my $attr (@{$self->attrs}) {
        my $key = $attr->name;
        my $val = $attr->get_value( $instance );
        $out->{$key} = $val;
    }
    return $out;
#    if (ref($pk_spec) eq 'ARRAY') {
#        my $out = { };
#        foreach my $pk_attr (@$pk_spec) {
#            my $val = $pk_attr->get_value($self);
#            if (not defined $val) {
#                undef $out;
#                last;
#            }
#            $out->{$pk_attr->name} = $val;
#        }
#        return $out;
#    }
#    return $pk_spec->get_value($self);
}

1;

__END__


