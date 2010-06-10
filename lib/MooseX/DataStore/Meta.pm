package MooseX::DataStore::Meta::Attribute::Trait::Persistent;
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
    required        => 1,
);

package Moose::Meta::Attribute::Custom::Trait::Persistent;
sub register_implementation {'MooseX::DataStore::Meta::Attribute::Trait::Persistent'}


package MooseX::DataStore::Meta::Class::Trait::DataObject;
use Moose::Role;

has 'primary_key' => (
    is              => 'rw',
    does            => 'MooseX::DataStore::Meta::Attribute::Trait::Persistent',
);

has 'table' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'persistent_attributes' => (
    isa             => 'ArrayRef[Moose::Meta::Attribute]',
    is              => 'rw',
    default         => sub { [] },
);

has 'attribute_to_column' => (
    isa             => 'HashRef[Str]',
    is              => 'rw',
    default         => sub { {} },
);

sub configure {
    my ($self, %p) = @_;
    my $metaclass = $self;
    if (exists $p{-table}) { $metaclass->table($p{-table}); }
    if (exists $p{-primary_key}) { $metaclass->primary_key( $metaclass->get_attribute( $p{-primary_key} ) ) }
    foreach my $attr ($metaclass->get_all_attributes) {
        if ($attr->does('MooseX::DataStore::Meta::Attribute::Trait::Persistent')) {
            push @{$metaclass->persistent_attributes}, $attr;
            $metaclass->attribute_to_column->{$attr->name} = $attr->column;
        }
    }
}


package Moose::Meta::Class::Custom::Trait::DataObject;
sub register_implementation { 'MooseX::DataStore::Meta::Class::Trait::DataObject' }


1;

__END__
