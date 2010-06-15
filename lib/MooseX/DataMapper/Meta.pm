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
        $attr_name = $fk_class->meta->primary_key->name;
    }
    my $attr = $fk_class->meta->get_attribute($attr_name);
    (defined $attr)
        or croak "ref_to attribute refers to an invalid/non-persistent attribute ($attr_name)";
    $self->ref_to_attr( $attr );
}


package Moose::Meta::Attribute::Custom::Trait::ForeignKey;
sub register_implementation {'MooseX::DataMapper::Meta::Attribute::Trait::ForeignKey'}


# =================================================================

package MooseX::DataMapper::Meta::Class::Trait::DataMapper::Class;
use Moose::Role;
use MooseX::DataMapper::Meta::Role;
use Carp;

has 'primary_key' => (
    is              => 'rw',
    does            => 'MooseX::DataMapper::Meta::Attribute::Trait::Persistent',
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


sub _get_reverse_fk_method {
    my ($self, $args) = @_;
    my $attr                = $args->{attr};
    my $ref_from            = $args->{ref_from};
    my $ref_from_attr       = $args->{ref_from_attr};
    my $ref_to_attr         = $args->{ref_to_attr};
    my $ref_to_attr_name    = $args->{ref_to_attr_name};
    my $ref_to_class        = $args->{ref_to_class};
    my $ref_from_class      = $ref_from_attr->associated_class->name;
    my $association_link    = $attr->association_link;
    return sub {
        my ($self) = @_;
        (defined $self->datamapper_session)
            or croak "Cannot access association ($association_link) in an unbound object";
        my $qs = MooseX::DataMapper::AssociationQuerySet->new( 
            session         => $self->datamapper_session,
            class_spec      => [$ref_from_class],
            parent_object   => $self,
            fk_attr         => $attr,
            ref_from_attr   => $ref_from_attr,
            ref_to_attr     => $ref_to_attr,
        );
        return $qs->static_filter({ $ref_from => $ref_to_attr->get_value($self) });
    };
}


sub _get_forward_fk_method_modifier {
    my ($self, $args) = @_;
    my $attr                = $args->{attr};
    my $ref_from            = $args->{ref_from};
    my $ref_from_attr       = $args->{ref_from_attr};
    my $ref_to_attr         = $args->{ref_to_attr};
    my $ref_to_attr_name    = $args->{ref_to_attr_name};
    my $ref_to_class        = $args->{ref_to_class};
    return sub {
        my $accessor = shift @_;
        my ($o, $fk) = @_;
        if (scalar @_ == 2) { # this is a set operation
            ($fk->isa($ref_to_class))
                or croak "Failed ForeignKey constraint, expects $ref_to_class";
            my $fk_id = $ref_to_attr->get_value($fk);
            if (defined $fk_id) {
                $ref_from_attr->set_value( $o, $fk_id );
            }
            else {
                # undef ids of foreign key assignments should clear the ref_from attribute
                $ref_from_attr->clear_value($o);
            }
            return $accessor->(@_);
        }
        else {
            # this is a read operation
            my $fk_id = $ref_from_attr->get_value($o);
            my $v = $attr->get_value($o);
            if (defined($fk_id) && not(defined $v)) {
                $fk = $o->datamapper_session->objects($ref_to_class)->get($fk_id);
                $attr->set_value($o, $fk); # cache!
                return $fk;
            }
            elsif (defined($v) && not(defined $fk_id)) {
            }
        }
        return $accessor->(@_);
    };
}


sub _add_persistent_attribute {
    my ($self, $attr) = @_;
    my $metaclass = $self;
    push @{$metaclass->persistent_attributes}, $attr;
    if (not defined $attr->column) {
        $attr->column( $attr->name ); # use the attribute name as the default column name
    }
    $metaclass->attribute_to_column->{$attr->name} = $attr->column;
    $metaclass->column_to_attribute->{$attr->column} = $attr->name;
}


sub datamapper_class_setup {
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
        if ($attr->does('MooseX::DataMapper::Meta::Attribute::Trait::Persistent')) {
            $self->_add_persistent_attribute($attr);
        }
        elsif ($attr->does('MooseX::DataMapper::Meta::Attribute::Trait::ForeignKey')) {
            push @{$metaclass->foreignkey_attributes}, $attr;
            $attr->init_ref_to;

            my $ref_to_attr = $attr->ref_to_attr;
            my $ref_to_attr_name = $ref_to_attr->name;
            my $ref_to_class = $ref_to_attr->associated_class->name;

            # setup ref_from
            
            if (not defined $attr->ref_from) {
                my $name = lc($ref_to_class).'_'.lc($ref_to_attr_name);
                my $x = $metaclass->add_attribute(
                    $name => {
                        traits              => [qw/Persistent/],
                        column              => $name,
                        isa                 => 'Int',
                        is                  => 'rw',
                    },
                );
                $self->_add_persistent_attribute($x);
                $attr->ref_from($name);
            }
            my $ref_from = $attr->ref_from;
            my $ref_from_attr = $metaclass->get_attribute($ref_from);
            (defined($ref_from_attr) && $ref_from_attr->does("Persistent"))
                or croak "ref_from for class ".$metaclass->name." refers to an invalid/non-persistent attribute";
            $attr->ref_from_attr($ref_from_attr);            

            # check association link 
            (not $ref_to_class->can( $attr->association_link ))
                or croak "association_link ".$attr->association_link." refers to an already existing method in class ".$ref_to_class->meta->name;

            # wrappers to simple fk relationship
            my $args = {
                attr                => $attr,
                ref_from            => $ref_from,
                ref_from_attr       => $ref_from_attr,
                ref_to_attr         => $ref_to_attr,
                ref_to_attr_name    => $ref_to_attr_name,
                ref_to_class        => $ref_to_class,
            };
            $metaclass->add_around_method_modifier( $attr->name, $self->_get_forward_fk_method_modifier( $args ) );
            $ref_to_class->meta->add_method( $attr->association_link, $self->_get_reverse_fk_method( $args ) );
        }
    }
    MooseX::DataMapper::Meta::Role->meta->apply($metaclass);
}


package Moose::Meta::Class::Custom::Trait::DataMapper::Class;
sub register_implementation { 'MooseX::DataMapper::Meta::Class::Trait::DataMapper::Class' }


1;

__END__
