package Company;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);


package Employee;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;
use Carp;

has 'name' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

has 'bio' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
    lazy_select         => 1,
);

has 'company' => (
    traits              => [qw/ForeignKey/],
    ref_to              => [qw/Company/],
    association_link    => 'employees',
    is                  => 'rw',
);

package main;

Company->meta->datamapper_class_setup( -table => 'company' );
Employee->meta->datamapper_class_setup( -table => 'employee' );


1;

__END__
