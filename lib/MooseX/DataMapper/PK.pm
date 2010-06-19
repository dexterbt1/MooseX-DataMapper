package MooseX::DataMapper::PK;
use Moose::Role;

requires 'get_column_condition';
requires 'is_serial';
requires 'get_instance_value';

# dirty PK management
requires 'is_dirty';
requires 'cleanup_dirty';
requires 'get_dirty_columns';

1;

__END__
