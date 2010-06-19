package # hide from PAUSE
    Person;

use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;
use MooseX::DataMapper::ColumnHandlers::DateTime qw/from_date to_date/;
use DateTime::Format::SQLite; 

# demonstrate ColumnHandlers

has 'name' => ( 
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

# here, we'll use a non-portable way of inflating/deflating DateTime
has 'birth_date' => (
    traits              => [qw/Persistent WithColumnHandler/],
    isa                 => 'DateTime',
    is                  => 'rw',
    from_db             => sub { DateTime::Format::SQLite->parse_date($_[0]) },
    to_db               => sub { DateTime::Format::SQLite->format_date($_[0]) },
);

# this is more portable handling of datetime
has 'birth_date_copy' => (
    traits              => [qw/Persistent WithColumnHandler/],
    isa                 => 'DateTime',
    is                  => 'rw',
    from_db             => to_date,
    to_db               => from_date,
);

__PACKAGE__->meta->datamapper_class_setup(
    -table          => 'person',
    -auto_pk        => 'id',
);

1;

__END__
