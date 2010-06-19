package MooseX::DataMapper::Meta::Attribute::Trait::Persistent;
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'lazy_select' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 0,
);

package Moose::Meta::Attribute::Custom::Trait::Persistent;
sub register_implementation {'MooseX::DataMapper::Meta::Attribute::Trait::Persistent'}


# =================================================================


package MooseX::DataMapper::Meta::Attribute::Trait::ForeignKey;
use strict;
use Moose::Role;
use Carp;
use Data::Dumper;

# public
has 'ref_from' => (
    isa             => 'Str',
    is              => 'rw',
);

# private
has 'ref_from_attr' => (
    isa             => 'Moose::Meta::Attribute',
    is              => 'rw',
);

# private
has 'ref_to_attr' => (
    isa             => 'Moose::Meta::Attribute',
    is              => 'rw',
);

# public
has 'ref_to' => (
    isa             => 'ArrayRef[Str]',
    is              => 'rw',
    required        => 1,
);

# public
has 'association_link' => (
    isa             => 'Str',
    is              => 'rw',
    required        => 1,
);

# private 
has 'association_attr' => (
    isa             => 'Moose::Meta::Attribute',
    is              => 'rw',
);

sub init_ref_to {
    my ($self) = @_;
    my $v = $self->ref_to;
    my ($fk_class, $attr_name) = @$v;
    ($fk_class->can('does') && $fk_class->does('MooseX::DataMapper::Meta::Role'))
        or croak "ref_to attribute refers to an invalid/non-persistent fk_class ($fk_class)";
    if (not defined $attr_name) {
        # implicitly use the primary key of the fk_class
        # FIXME: hardwire support for SERIAL primary, for now
        $attr_name = $fk_class->meta->primary_key->attr->name;
    }
    my $attr = $fk_class->meta->get_attribute($attr_name);
    (defined $attr)
        or croak "ref_to attribute refers to an invalid/non-persistent attribute ($attr_name)";
    $self->ref_to_attr( $attr );
}


package Moose::Meta::Attribute::Custom::Trait::ForeignKey;
sub register_implementation {'MooseX::DataMapper::Meta::Attribute::Trait::ForeignKey'}


# =================================================================


package MooseX::DataMapper::Meta::Attribute::Trait::WithColumnHandler;
use strict;
use Moose::Role;

has 'to_db' => (
    isa             => 'CodeRef',
    is              => 'rw',
    required        => 1,
);

has 'from_db' => (
    isa             => 'CodeRef',
    is              => 'rw',
    required        => 1,
);

package Moose::Meta::Attribute::Custom::Trait::WithColumnHandler;
sub register_implementation {'MooseX::DataMapper::Meta::Attribute::Trait::WithColumnHandler'}


# =================================================================


1;

__END__
