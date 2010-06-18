use strict;
use warnings;

package # hide from PAUSE
    X;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;
use Test::More qw/no_plan/;
use Test::Exception;

has 'a' => (
    traits      => [qw/Persistent/],
    isa         => 'Int',
    is          => 'rw',
);

has 'b' => (
    traits      => [qw/Persistent/],
    isa         => 'Int',
    is          => 'rw',
    column      => 'a',
);

my @attributes =  X->meta->get_all_attributes;

is scalar @attributes, 2;

dies_ok {
    X->meta->datamapper_class_setup(
        -table  => 'x',
    );
} 'dup column';

ok 1;

1;

__END__
