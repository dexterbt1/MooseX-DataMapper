package MooseX::DataMapper::PK;
use Moose::Role;

requires 'get_column_condition';
requires 'is_serial';
requires 'get_instance_value';

1;

__END__
