package MooseX::DataMapper::Meta::TupleBuilder::ClassToSingleTable;
use strict;
use Carp;
use Moose::Role;

# get_tuples( $object_instance, $session, $table_spec )
# - returns something like:
# {
#     table1 => [
#         {
#             column1 => value,
#             column2 => value,
#             ...
#         }, # this is a single row
#         ... # and more if necessary
#     ],
#     ... # more tables if necessary
# }
#
sub get_tuples {
    my ($self, $i, $datamapper_session, $table_spec) = @_;
    my $table = $table_spec; # assume table spec as a single table, plain string
    my $driver_name = $datamapper_session->dbh->get_info(17);
    my $metaclass = $i->meta;
    my $pk = $metaclass->primary_key;
    my $o = { };
    foreach my $attr (@{$metaclass->persistent_attributes}) {
        my $column = $attr->column;
        my $value = $attr->get_value($i);
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
