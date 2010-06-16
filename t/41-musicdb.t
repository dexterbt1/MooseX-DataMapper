#!/usr/bin/perl
use strict;
use MooseX::DataMapper;

package Artist;
use Moose -traits => qw/DataMapper::Class/;

has 'id' => (
    traits              => [qw/Persistent/],
    column              => 'artistid',
    isa                 => 'Int',
    is                  => 'rw',
);

has 'name' => (
    traits              => [qw/Persistent/],
    column              => 'name', 
    isa                 => 'Str',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup( 
    -table              => 'artists', # default table
    -primary_key        => 'id',
);

package CD;
use Moose -traits => qw/DataMapper::Class/;
use DateTime;
use MooseX::DataMapper::ColumnHandlers::DateTime qw/from_year to_year/;

has 'cdid' => ( 
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
);

has 'title' => (
    traits              => [qw/Persistent/],
    isa                 => 'Str',
    is                  => 'rw',
);

has 'year' => (
    traits              => [qw/Persistent WithColumnHandler/],
    isa                 => 'DateTime',
    is                  => 'rw',
    from_db             => to_year,
    to_db               => from_year,
);

has 'artistid' => (
    traits              => [qw/Persistent/],
    isa                 => 'Int',
    is                  => 'rw',
);

has 'artist' => (
    traits              => [qw/ForeignKey/],
    ref_to              => [qw/Artist id/],
    ref_from            => 'artistid',
    association_link    => 'cds',
    isa                 => 'Artist',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup(
    -table              => 'cd',
    -primary_key        => 'cdid',
);



package main;
use strict;
use MooseX::DataMapper;
use Test::More qw/no_plan/;
use Test::Exception;

Artist->meta->table('artist'); # override the default table

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
    require 't/XPointRect.pm';
}

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE artist (artistid INTEGER PRIMARY KEY AUTOINCREMENT, name INTEGER)
EOT
$dbh->do(<<"EOT");
    CREATE TABLE cd (cdid INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, year INT, artistid INTEGER REFERENCES artist (artistid))
EOT

my $ds;

ok 1;

__END__
