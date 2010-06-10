package Person;
use strict;
use warnings;
use MooseX::DataStore;
use Moose -traits => qw/DataObject/;
with 'MooseX::DataStore::Class';

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



1;

__END__
