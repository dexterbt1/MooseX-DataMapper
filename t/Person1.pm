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

__PACKAGE__->meta->configure(
    -table              => 'person',
    -primary_key        => 'id',
);

=cut

package Address;
use strict;
use MooseX::DataStore;
use Moose -traits => qw/DataObject/;
with 'MooseX::DataStore::Class';

# implicit autoincrement primary key id is generated here

has 'person_id' => (
    traits              => [qw/Persistent/],
    column              => 'person_id',
    isa                 => 'Int',
    is                  => 'rw',
);

has 'person' => (
    traits              => [qw/ForeignKey/],
    reference_using     => ['person_id'],
    isa                 => 'Person',
    is                  => 'rw',
);

__PACKAGE__->meta->configure(
    -table              => 'address',
);

=cut



1;

__END__
