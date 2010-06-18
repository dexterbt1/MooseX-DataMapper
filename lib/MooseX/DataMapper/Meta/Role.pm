package MooseX::DataMapper::Meta::Role;
use strict;
use Moose::Role;
use Carp;

# inside-out 
my $session_of = { };
sub datamapper_session {
    my $self = shift @_;
    if (@_) {
        $session_of->{"$self"} = shift @_;
    }
    return $session_of->{"$self"};
}

sub pk {
    my $self = shift @_;
    my $pk_attr = $self->meta->primary_key;
    return $pk_attr->get_value($self);
}

sub get_sql_data_hash {
    my ($self, $caller_session, $t_alias) = @_;
    my $metaclass = $self->meta;
    my $o = { };
    my $table_alias = $t_alias || $metaclass->table;
    my $driver_name = $caller_session->dbh->get_info(17);
    foreach my $attr (@{$metaclass->persistent_attributes}) {
        my $attr_name = $attr->name;
        my $column = $attr->column;
        my $value = $attr->get_value($self);
        if ( ($metaclass->primary_key->name eq $attr_name) and (not defined $value) ) {
            next; # skip undefined primary keys
        }
        #my $k = $self->session->dbh->quote_identifier( $column );
        my $k = $column;
        $o->{$k} = $value;
        if ($attr->does('WithColumnHandler')) {
            $o->{$k} = $attr->to_db->($value, $driver_name);
        }
    }
    return $o;
}

sub DESTROY {
    my ($self) = @_;
    delete $session_of->{"$self"};
}

1;

__END__
