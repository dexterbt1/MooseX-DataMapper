package MooseX::DataMapper::QuerySet::Conjunction;
use strict;
use Moose;
use Carp;

has 'term' => (
    isa         => 'Str',
    is          => 'rw',
    required    => 1,
);

1;

__END__
