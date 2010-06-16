#!/usr/bin/perl
package Music::Artist;
use strict;
use MooseX::DataMapper;
use Moose -traits => qw/DataMapper::Class/;

has 'id' => (
    traits              => [qw/Persistent/],
    column              => 'artistid',
    isa                 => 'Int',
    is                  => 'rw',
);

has 'name' => (
    traits              => [qw/Persistent/],
    column              => 'artistname', 
    isa                 => 'Str',
    is                  => 'rw',
);

__PACKAGE__->meta->datamapper_class_setup( 
    -table              => 'artists', # default table
    -primary_key        => 'id', # note, this refers to the attribute name
);

package Music::CD;
use Moose -traits => qw/DataMapper::Class/;
use DateTime;
use MooseX::DataMapper::ColumnHandlers::DateTime qw/from_year to_year/;

# shown here, if an attribute's column is omitted,
#   then by default, column name = attribute name 

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

has 'release_year' => (
    traits              => [qw/Persistent WithColumnHandler/],
    column              => 'year',
    isa                 => 'DateTime', # coerce will probably be useful here
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
    ref_to              => [qw/Music::Artist id/],
    ref_from            => 'artistid',
    association_link    => 'cds',
    isa                 => 'Music::Artist',
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

Music::Artist->meta->table('artist'); # override the default table

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE artist (
        artistid INTEGER PRIMARY KEY AUTOINCREMENT, 
        artistname INTEGER
    )
EOT
$dbh->do(<<"EOT");
    CREATE TABLE cd (
        cdid INTEGER PRIMARY KEY AUTOINCREMENT, 
        title VARCHAR, 
        year INT, 
        artistid INTEGER REFERENCES artist (artistid)
    )
EOT

# in theory, the session object should not be a concern of your domain models.
my $session = MooseX::DataMapper->connect($dbh);

my $mj = Music::Artist->new( name => 'Michael Jackson' );

$session->save( $mj ); # inserts

my $thriller = Music::CD->new( 
    title           => 'Thriller', 
    release_year    => DateTime->new( year => 1981 ),
    artist          => $mj, # manually assign
);
$session->save( $thriller ); # inserts

$thriller->release_year->set_year( 1982 ); 
$session->save( $thriller ); # updates

# automatically associate "Bad" to the artist $mj
$mj->cds->save( 
    Music::CD->new( title => "Bad", release_year => DateTime->new( year => 1987 ) )
);

my $unreleased1 = Music::CD->new( title => 'This Is It', artist => $mj );
my $unreleased2 = Music::CD->new( title => 'Unknown', artist => $mj );

$session->save( $unreleased1 ); # inserts
$session->save( $unreleased2 ); # inserts

$session->delete( $unreleased1 ); # direct delete

$mj->cds->delete( $unreleased2 ); # delete object thru the association_link


my $october_album = Music::CD->new( 
    title           => 'October', 
    release_year    => DateTime->new( year => 1981 ),
    artist          => Music::Artist->new( name => 'U2' ),
);
# 1-level deep, saves october and u2 in one go
$session->save_deep( $october_album, 1 );                   

my $all_artists = $session->objects('Music::Artist')->all;

# several ways to retrieve u2, using chained queryset filters
my $u2          = $session->objects('Music::Artist')
                          ->filter('name = ?', 'U2')        # $stmt, @bind style
                          ->first;                          # returns a single object

my $u2_copy     = $session->objects('Music::Artist')
                          ->get( $u2->id );                 # by primary key

my $u2_copy2    = $session->objects('Music::Artist')
                          ->filter({ name => 'U2' })        # SQL::Abstract style
                          ->limit(1)
                          ->all                             # returns an arrayref of objects
                          ->[0];                            # semi-unsafe, direct index

# manually filter by foreign key object
my $mj_cds = $session->objects('Music::CD')->filter({ artist => $mj })->all;

# or directly access the association_link method of an instance
foreach my $cd (@{$mj->cds->all}) {
    # artist is lazily resolved (and cached) during access
    print join(", ", $cd->artist->name, $cd->title, $cd->release_year->year), "\n";
}

# explicit conjunctions for multiple chained filters
my $mj_and_u2   = $session->objects('Music::Artist')
                          ->filter('name LIKE ?', 'Michael%')
                          ->or
                          ->filter( { id => $u2->id } )
                          ->all;


ok 1;

__END__
