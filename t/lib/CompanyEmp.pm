package # hide from PAUSE
    Company;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'company',
);


package # hide from PAUSE
    Employee;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;
use Carp;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

has 'company' => (
    traits              => [qw/ForeignKey/],
    ref_to              => [qw/Company/],
    association_link    => 'employees',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'employee',
);



1;

__END__
