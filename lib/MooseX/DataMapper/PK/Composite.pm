package MooseX::DataMapper::PK::Composite;
use Moose;
use Carp;
use Scalar::Util qw/blessed/;

with 'MooseX::DataMapper::PK';

has 'source_meta' => (
    isa         => 'Moose::Meta::Class',
    is          => 'rw',
    required    => 1,
);

has 'pks' => (
    does        => 'ArrayRef[MooseX::DataMapper::PK]',
    is          => 'rw',
    required    => 1,
);

has 'pk_of' => (
    isa         => 'HashRef[MooseX::DataMapper::PK]',
    is          => 'rw',
);


sub BUILDARGS {
    my ($self, $source_meta, $spec) = @_;
    if (ref($spec) eq 'ARRAY') {
        # assume each spec_item is a Natural Key
        my @pks = ();
        my $pk_of = { };
        foreach my $attr_name (@$spec) {
            my $pk = MooseX::DataMapper::PK::Natural->new( $source_meta, $attr_name );
            push @pks, $pk;
            $pk_of->{$attr_name} = $pk;
        }
        return {
            source_meta     => $source_meta,
            pks             => \@pks,
            pk_of           => $pk_of,
        };
    }
    else {
        croak "Unsupported Composite Primary Key spec";
    }
}


sub is_serial { 0 }
sub set_serial { croak "Unimplemented"; }
sub clear_serial { croak "Unimplemented"; }


sub get_column_condition {
    my ($self, $obj ) = @_;
    my %out = ( );
    if (blessed $obj) {
        foreach my $pk (@{$self->pks}) {
            %out = ( %out, %{$pk->get_column_condition($obj)} );
        }
    }
    else {
        # assume a HASHREF
        (ref($obj) eq 'HASH')
            or croak "Unsupported column condition format for composite keys";
        my $user_params = $obj;
        # validate hashref, convert attributes to columns
        my $source_meta = $self->source_meta;
        foreach my $user_attr_name (keys %$user_params) {
            (exists $self->pk_of->{$user_attr_name}) 
                or croak "Unresolved attribute $user_attr_name used in composite primary key condition";
            my $pk = $self->pk_of->{$user_attr_name};
            %out = ( %out, %{$pk->get_column_condition($user_params->{$user_attr_name})} );
        }
    }
    return \%out;
}


sub get_instance_value {
    my ($self, $instance) = @_;
    my %out = ();
    foreach my $pk (@{$self->pks}) {
        %out = ( %out, $pk->attr->name() => $pk->get_instance_value($instance) );
    }
    return \%out;
}


sub is_dirty {
    my ($self, $obj) = @_;
    foreach my $pk (@{$self->pks}) {
        return 1 if ($pk->is_dirty($obj));
    }
    return 0;
}

sub cleanup_dirty {
    my ($self, $obj) = @_;
    foreach my $pk (@{$self->pks}) {
        $pk->cleanup_dirty($obj);
    }
}

sub get_dirty_columns {
    my ($self, $obj) = @_;
    my %out = ( );
    foreach my $pk (@{$self->pks}) {
        %out = ( %out, %{$pk->get_dirty_columns($obj)} );
    }
    return \%out;
}


1;

__END__


