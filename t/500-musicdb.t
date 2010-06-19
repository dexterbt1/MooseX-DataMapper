#!/usr/bin/perl
use strict;
{
#### Class Declarations

    package Music::Artist;
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
        -table              => 'artists',   # default table
        -primary_key        => 'id',        # note, refers to attribute name
    );

    package Music::CD;
    use Moose -traits => qw/DataMapper::Class/;
    use DateTime;
    use MooseX::DataMapper::ColumnHandlers::DateTime qw/from_year to_year/;

    # if an attribute's column is omitted, then column name = attribute name 

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
        -auto_pk            => 'cdid',   # generates a serial/auto-increment pk called 'cdid'
    );


#### Meta and Sessions


    package main;
    use strict;
    use MooseX::DataMapper;

    # you can override the default table
    Music::Artist->meta->table('artist'); 

    # create the tables for the demo
    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
    $dbh->do(q{ CREATE TABLE artist (artistid INTEGER PRIMARY KEY AUTOINCREMENT, artistname INTEGER) });
    $dbh->do(q{ CREATE TABLE cd (cdid INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, year INT, 
                    artistid INTEGER REFERENCES artist (artistid))
    });

    # in theory, the session object should not be a concern of your domain models.
    my $session = MooseX::DataMapper->connect($dbh);


#### Insert/Update/Delete and Relationships


    my $mj = Music::Artist->new( name => 'Michael Jackson' );

    $session->save( $mj ); # inserts

    my $thriller = Music::CD->new( 
        title           => 'Thriller', 
        release_year    => DateTime->new( year => 1981 ),
        artist          => $mj,
    );
    $session->save( $thriller ); # inserts

    $thriller->release_year->set_year( 1982 ); # 1981 was the wrong year, so change it 

    $session->save( $thriller ); # updates

    # save thru the association link method, this will automatically 
    # associate "Bad" cd to the artist $mj
    $mj->cds->save( 
        Music::CD->new( title => "Bad", release_year => DateTime->new( year => 1987 ) )
    );

    my $unreleased1 = Music::CD->new( title => 'This Is It', artist => $mj );

    # manually assign artist thru the persistent FK attr
    my $unreleased2 = Music::CD->new( title => 'Unknown', artistid => $mj->id );

    $session->save( $unreleased1 ); # inserts
    $session->save( $unreleased2 ); # inserts

    $session->delete( $unreleased1 ); # direct delete

    $mj->cds->delete( $unreleased2 ); # delete object thru the association_link

    my $october_album = Music::CD->new( 
        title           => 'October', 
        release_year    => DateTime->new( year => 1981 ),
        artist          => Music::Artist->new( name => 'U2' ),
    );

    # this saves october and u2 in one go, saves objects FKs 1-level deep (include artist)
    # by default, save_deep() has unlimited traversal of the object graph of foreign keys
    $session->save_deep( $october_album, 1 );                   


#### QuerySets


    my $all_artists = $session->objects('Music::Artist')->all;

    # several ways to retrieve u2
    my $u2          = $session->objects('Music::Artist')
                              ->filter('name LIKE ?', 'U2')     # $stmt, @bind style
                              ->first;                          # returns a single object

    my $u2_copy     = $session->objects('Music::Artist')
                              ->get( $u2->id );                 # by primary key

    my $u2_copy2    = $session->objects('Music::Artist')
                              ->filter({ name => 'U2' })        # SQL::Abstract style
                              ->limit(1)
                              ->all                             # returns an arrayref of objects
                              ->[0];                            # semi-unsafe, direct index

    # filter by foreign key object
    my $mj_cds = $session->objects('Music::CD')->filter({ artist => $mj })->all;

    # or directly access the association_link method of an instance
    foreach my $cd (@{$mj->cds->all}) {
        # artist is lazily resolved (and cached) during access
        print join(", ", $cd->artist->name, $cd->title, $cd->release_year->year), "\n";
    }

    # explicit logical operators for multiple unambiguous chained filters
    my $mj_and_u2   = $session->objects('Music::Artist')
                              ->filter('name LIKE ?', 'Michael%')
                              ->or
                              ->filter( { id => $u2->id } )
                              ->all;

}
package main;
use strict;
use Test::More qw/no_plan/;

ok 1;

__END__

this is a mirror copy of what's in the readme
