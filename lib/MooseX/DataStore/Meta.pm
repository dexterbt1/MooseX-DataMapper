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


# =================================================================


package MooseX::DataStore::Meta::Attribute::Trait::ForeignKey;
use strict;
use Moose::Role;
use Carp;
use Data::Dumper;

has 'ref_from' => (
    isa             => 'Str',
    is              => 'rw',
    required        => 1,
    trigger         => sub {
        my ($self, $v) = @_;
        # TODO: this is a hack, while I don't know the proper solution for this: 
        # we need to in order to check for correct
        my $class = $self->definition_context->{package};
        my $attr = $class->meta->get_attribute($v);
        (defined($attr) && ($attr->does('Persistent')))
            or croak "ref_from refers to an invalid/non-persistent attribute ($v)";
    },
);

has 'ref_to_attr' => (
    isa             => 'Moose::Meta::Attribute',
    is              => 'rw',
);

has 'ref_to' => (
    isa             => 'ArrayRef[Str]',
    is              => 'rw',
    required        => 1,
    trigger         => sub {
        my ($self, $v) = @_;
        my ($fk_class, $attr_name) = @$v;
        ($fk_class->can('does') && $fk_class->does('MooseX::DataStore::Meta::Role'))
            or croak "ref_to fk_class refers to an invalid/non-persistent fk_class ($fk_class)";
        my $attr = $fk_class->meta->get_attribute($attr_name);
        (defined $attr)
            or croak "ref_to attribute refers to an invalid/non-persistent attribute ($attr_name)";
        $self->ref_to_attr( $attr );
    },
);



package Moose::Meta::Attribute::Custom::Trait::ForeignKey;
sub register_implementation {'MooseX::DataStore::Meta::Attribute::Trait::ForeignKey'}


# =================================================================

package MooseX::DataStore::Meta::Class::Trait::DataStore::Class;
use Moose::Role;
use MooseX::DataStore::Meta::Role;
use Carp;

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

has 'foreignkey_attributes' => (
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
        elsif ($attr->does('MooseX::DataStore::Meta::Attribute::Trait::ForeignKey')) {
            push @{$metaclass->foreignkey_attributes}, $attr;
            my $ref_from = $attr->ref_from;
            my $ref_from_attr = $metaclass->get_attribute($ref_from);
            my $ref_to_attr = $attr->ref_to_attr;
            my $ref_to_attr_name = $ref_to_attr->name;
            my $ref_to_class = $ref_to_attr->associated_class->name;
            # replace accessor 
            $metaclass->add_around_method_modifier( $attr->name, sub {
                my $accessor = shift @_;
                my ($o, $fk) = @_;
                if (scalar @_ == 2) { # this is a set operation
                    ($fk->isa($ref_to_class))
                        or croak "Failed ForeignKey constraint, expects $ref_to_class";
                    my $fk_id = $fk->$ref_to_attr_name;
                    if (defined $fk_id) {
                        $o->$ref_from( $fk_id );
                    }
                    else {
                        # undef ids of foreign key assignments should clear the ref_from attribute
                        $ref_from_attr->clear_value($o);
                    }
                    return $accessor->(@_);
                }
                else {
                    my $fk_id = $o->$ref_from;
                    my $v = $attr->get_value($o);
                    if (defined($fk_id) && not(defined $v)) {
                        $fk = $o->datastore->find($ref_to_class)->get_nocache($fk_id);
                        $attr->set_value($o, $fk); # cache!
                        return $fk;
                    }
                    elsif (defined($v) && not(defined $fk_id)) {
                    }
                }
                return $accessor->(@_);
            });
        }
    }
    MooseX::DataStore::Meta::Role->meta->apply($metaclass);
}


package Moose::Meta::Class::Custom::Trait::DataStore::Class;
sub register_implementation { 'MooseX::DataStore::Meta::Class::Trait::DataStore::Class' }


1;

__END__
