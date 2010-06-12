package MooseX::DataStore::Meta::Role;
use strict;
use Moose::Role;
use Carp;

# inside-out 
my $datastore_of = { };
sub datastore {
    my $self = shift @_;
    if (@_) {
        $datastore_of->{"$self"} = shift @_;
    }
    return $datastore_of->{"$self"};
}

sub pk {
    my $self = shift @_;
    my $attr_name = $self->meta->primary_key->name;
    return $self->$attr_name;
}

sub get_data_hash {
    my ($self, $t_alias) = @_;
    my $metaclass = $self->meta;
    my $o = { };
    my $table_alias = $t_alias || $metaclass->table;
    foreach my $attr (@{$metaclass->persistent_attributes}) {
        my $attr_name = $attr->name;
        my $column = $attr->column;
        my $value = $self->$attr_name;
        if ( ($metaclass->primary_key->name eq $attr_name) and (not defined $value) ) {
            next; # skip undefined primary keys
        }
        #my $k = $self->datastore->dbh->quote_identifier( $column );
        my $k = $column;
        $o->{$k} = $value;
    }
    return $o;
}

1;

__END__
