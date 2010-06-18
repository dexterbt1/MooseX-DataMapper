package MooseX::DataMapper::Meta::TupleBuilder::ClassToSingleTable;
use strict;
use Carp;
use Moose::Role;

sub get_tuples {
    my ($self, $i, $datamapper_session, $table_or_alias) = @_;
    my $table = $table_or_alias;
    my $driver_name = $datamapper_session->dbh->get_info(17);
    my $metaclass = $i->meta;
    my $o = { };
    foreach my $attr (@{$metaclass->persistent_attributes}) {
        my $column = $attr->column;
        my $value = $attr->get_value($i);
        if ( ($metaclass->primary_key->name eq $attr->name) and (not defined $value) ) {
            next; # skip undefined primary keys
        }
        my $k = $column;
        $o->{$k} = $value;
        if ($attr->does('WithColumnHandler')) {
            $o->{$k} = $attr->to_db->($value, $driver_name);
        }
    }
    return { $table => [ $o ] };
}

1;

__END__
