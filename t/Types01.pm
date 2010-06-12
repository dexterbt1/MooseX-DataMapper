package Company;
use strict;
use MooseX::DataStore;
use Moose -traits => qw/DataStore::Class/;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

__PACKAGE__->meta->datastore_class_setup(
    -table              => 'company',
);


package Employee;
use strict;
use MooseX::DataStore;
use Moose -traits => qw/DataStore::Class/;
use Carp;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

has 'company' => (
    traits              => [qw/ForeignKey/],
    ref_to              => [qw/Company/],
    reverse_link        => 'employees',
    is                  => 'rw',
);

__PACKAGE__->meta->datastore_class_setup(
    -table              => 'employee',
);



1;

__END__
