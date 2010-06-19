use strict;
package MooseX::DataMapper::Meta::Class::Trait::DataMapper::Class;
use Moose::Role;
use MooseX::DataMapper::PK::Serial;
use MooseX::DataMapper::PK::Natural;
use MooseX::DataMapper::PK::Composite;
use MooseX::DataMapper::Meta::Role;
use MooseX::DataMapper::Meta::TupleBuilder;
use Carp;

has 'primary_key' => (
    is              => 'rw',
    does            => 'MooseX::DataMapper::PK',
);

has 'table' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'tuple_builder_class' => (
    isa             => 'Str',
    is              => 'rw',
    lazy            => 1,
    default         => 'MooseX::DataMapper::Meta::TupleBuilder::ClassToSingleTable',
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
    my ($self, $name) = @_;
    my $auto_pk = $self->add_attribute(
        $name => {
            traits              => [qw/Persistent/],
            column              => $name,
            isa                 => 'Int',
            is                  => 'rw',
        },
    );
    $self->map_primary_key( $name, 'Serial' );
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
                # this is a volatile algo, since we'll depend on the 
                my $ds = $o->datamapper_session
                    or die "Cannot access foreignkey object for unbound object";
                $fk = $ds->objects($ref_to_class)->get($fk_id);
                $attr->set_value($o, $fk); # cache!
                return $fk;
            }
            elsif (defined($v) && not(defined $fk_id)) {
            }
        }
        return $accessor->(@_);
    };
}


sub map_attr_column {
    my ($self, $attr_name, $column_spec) = @_;
    my $attr = $self->get_attribute($attr_name)
        or croak "Unable to remap invalid attribute ($attr_name)";
    ($attr->does('Persistent'))
        or croak "Cannot remap non-persistent attribute ($attr_name)";
    (not exists $self->column_to_attribute->{$column_spec})
        or croak "Cannot remap, duplicate column";
    my $old_column = $attr->column || '';
    delete $self->attribute_to_column->{$attr_name};
    delete $self->column_to_attribute->{$old_column};
    $attr->column( $column_spec );
    $self->attribute_to_column->{$attr->name} = $attr->column;
    $self->column_to_attribute->{$attr->column} = $attr->name;
    $self->persistent_attributes( 
        [ map { $self->get_attribute($_) } values %{$self->column_to_attribute} ] 
    );
}


sub map_primary_key {
    my ($self, $spec, $pk_type) = @_;
    (defined $spec)
        or croak "Undefined primary key spec";
    my $class_prefix = 'MooseX::DataMapper::PK';
    my $pk_class = join('::', $class_prefix, $pk_type || 'Serial' );
    my $out = $pk_class->new( $self, $spec );
    $self->primary_key( $out );
}


sub datamapper_class_setup {
    my ($self, %p) = @_;
    my $metaclass = $self;
    # handle setup params
    if (exists $p{'-table'}) { $metaclass->table($p{'-table'}); }
    if (exists $p{'-primary_key'}) { 
        $self->map_primary_key( $p{'-primary_key'}, $p{'-primary_key_type'} );
    }
    if (exists $p{'-auto_pk'}) {
        (not exists $p{'-primary_key'})
            or croak "Cannot apply -auto_pk, conflicts with -primary_key definition";
        $self->_add_auto_pk( $p{'-auto_pk'} );
    }
    
    # --- do setup
    foreach my $attr ($metaclass->get_all_attributes) {
        if ($attr->does('Persistent')) {
            $self->map_attr_column($attr->name, $attr->column || $attr->name);
        }
        elsif ($attr->does('ForeignKey')) {
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
                $self->map_attr_column($name, $name);
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
            # FIXME: should method be the $attr->accessor? more tests on this later
            $metaclass->add_around_method_modifier( $attr->name, $self->_get_forward_fk_method_modifier( $args ) );
            $ref_to_class->meta->add_method( $attr->association_link, $self->_get_reverse_fk_method( $args ) );
        }
    }
    $self->tuple_builder_class->meta->apply($metaclass->meta);
    MooseX::DataMapper::Meta::Role->meta->apply($metaclass);
    if (not $self->primary_key) {
        croak "No Primary Key specified. Perhaps you forgot -primary_key or -auto_pk ?";
    }
}


package Moose::Meta::Class::Custom::Trait::DataMapper::Class;
sub register_implementation { 'MooseX::DataMapper::Meta::Class::Trait::DataMapper::Class' }



1;

__END__
