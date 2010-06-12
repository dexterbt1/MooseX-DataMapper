package Person;
use strict;
use MooseX::DataStore;
use Moose -traits => qw/DataStore::Class/;

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

__PACKAGE__->meta->datastore_class_setup(
    -table              => 'person',
    -primary_key        => 'id',
);

package Address;
use strict;
use MooseX::DataStore;
use Moose -traits => qw/DataStore::Class/;

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
    reverse_link        => 'addresses',
    is                  => 'rw',
);

__PACKAGE__->meta->datastore_class_setup(
    -table              => 'address',
);



1;

__END__
