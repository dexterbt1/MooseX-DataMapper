package # hide from PAUSE
    X;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'a' => (
    traits      => [qw/Persistent/],
    isa         => 'Int',
    is          => 'rw',
);

has 'b' => (
    traits      => [qw/Persistent/],
    isa         => 'Int',
    is          => 'rw',
);

has 'c' => (
    traits      => [qw/Persistent/],
    isa         => 'Int',
    is          => 'rw',
);


__PACKAGE__->meta->datamapper_class_setup(
    -table          => 'x',
    -primary_key    => [ 'a', 'b' ],
);

1;

__END__
