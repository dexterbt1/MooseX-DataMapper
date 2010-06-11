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


package MooseX::DataStore::Meta::Class::Trait::DataStore::Class;
use Moose::Role;
use MooseX::DataStore::Meta::Role;

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

has 'column_to_attribute' => (
    isa             => 'HashRef[Str]',
    is              => 'rw',
    default         => sub { {} },
);

sub _add_auto_pk {
    my ($self) = @_;
    my $auto_pk = $self->add_attribute(
        id => {
            traits              => [qw/Persistent/],
            column              => 'id',
            isa                 => 'Int',
            is                  => 'rw',
        },
    );
    $self->primary_key( $auto_pk );
}

sub datastore_class_setup {
    my ($self, %p) = @_;
    my $metaclass = $self;
    if (exists $p{-table}) { $metaclass->table($p{-table}); }
    if (exists $p{-primary_key}) { 
        $metaclass->primary_key( $metaclass->get_attribute( $p{-primary_key} ) ) 
    }
    else {
        $self->_add_auto_pk;
    }
    foreach my $attr ($metaclass->get_all_attributes) {
        if ($attr->does('MooseX::DataStore::Meta::Attribute::Trait::Persistent')) {
            push @{$metaclass->persistent_attributes}, $attr;
            $metaclass->attribute_to_column->{$attr->name} = $attr->column;
            $metaclass->column_to_attribute->{$attr->column} = $attr->name;
        }
    }
    MooseX::DataStore::Meta::Role->meta->apply($metaclass);
}


package Moose::Meta::Class::Custom::Trait::DataStore::Class;
sub register_implementation { 'MooseX::DataStore::Meta::Class::Trait::DataStore::Class' }


1;

__END__
