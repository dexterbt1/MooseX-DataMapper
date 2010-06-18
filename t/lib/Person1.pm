package # hide from PAUSE
    Person;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'id' => (
    traits              => [qw/Persistent/],
    column              => 'uid',
    isa                 => 'Int',
    is                  => 'rw',
);

has 'name' => (
    traits              => [qw/Persistent/],
    column              => 'cname',
    isa                 => 'Str',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'person',
    -primary_key        => 'id',
);

package # hide from PAUSE
    Address;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

# implicit primary key id is generated here

has 'city' => (
    traits              => [qw/Persistent/],
    column              => 'city',
    isa                 => 'Str',    
    is                  => 'rw',
);

has 'person_id' => (
    traits              => [qw/Persistent/],
    column              => 'person_uid',
    isa                 => 'Int',
    is                  => 'rw',
);

has 'person' => (
    traits              => [qw/ForeignKey/],
    ref_from            => 'person_id',
    ref_to              => [qw/Person id/],
    association_link    => 'addresses',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'address',
);



1;

__END__
