package X;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'a' => (
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
);

has 'b' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
    writer              => 'set_b',
    reader              => 'get_b',
);


__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'x',
);


package Point;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has ['x', 'y'] => (
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'point',
);


package Rect;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;
use Carp;

has ['width', 'height'] => (
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
    trigger             => sub { ($_[1] >= 0) or croak "Expected non-zero width/height"; },
);

has 'point_id' => (
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
    writer              => 'set_point_id',
    reader              => 'get_point_id',
);

has 'point' => (
    traits              => [qw/ForeignKey/],
    ref_from            => 'point_id',
    ref_to              => [qw/Point id/],
    association_link    => 'rects',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'rect',
);



1;

__END__
