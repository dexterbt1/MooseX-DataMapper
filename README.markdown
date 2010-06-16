MooseX::DataMapper
==================

An object-relational mapper for persisting / querying Moose-based objects in SQL relational databases.

WARNING
-------

This is experimental / preview stuff and the API and implementaion is still highly fluid and is continuously evolving. This is not (yet) even packaged for / released in CPAN. Even the project name may later. Standard full disclaimer below. USE AT YOUR OWN RISK!


Overview
--------

#### Class Declarations

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
        -table              => 'artists',       # default table
        -primary_key        => 'id',            # note, this refers to the attribute name
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


#### Meta and Sessions


    package main;
    use strict;
    use MooseX::DataMapper;

    # you can override the default table
    Music::Artist->meta->table('artist'); 

    # create the tables for the demo
    my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
    $dbh->do(q{ CREATE TABLE artist (artistid INTEGER PRIMARY KEY AUTOINCREMENT, artistname INTEGER) })
    $dbh->do(q{ CREATE TABLE cd (cdid INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, year INT, 
                    artistid INTEGER REFERENCES artist (artistid))
    })

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

    # explicit conjunctions for multiple unambiguous chained filters
    my $mj_and_u2   = $session->objects('Music::Artist')
                              ->filter('name LIKE ?', 'Michael%')
                              ->or
                              ->filter( { id => $u2->id } )
                              ->all;


Features (so far)
-----------------
* Basic single class/table CRUD
* Chainable DSL-like query API based on attributes
* Support for ForeignKey with assocation (reverse) link
* Custom ColumnHandlers for inflation/deflation of more complex objects


TODO / Upcoming:
----------------

* Custom Columns / Aggregation
* Order-by / Group-By
* Iterators
* Lazy-loaded fields
* Joins
* Many-To-Many, Cyclic References
* Inheritance
* Eager-loading
* ... and likely lot more needing to be addressed


Requirements
------------

* Moose
* SQL::Abstract
* SQL::Abstract::Limit
* DBIx::Simple
* DBD::SQLite
* DateTime
* DateTime::Format::SQLite
* DateTime::Format::MySQL
* DateTime::Format::Pg


Notes
-----

Why yet another ORM? This project stemmed from getting tired of all my duplicated mapping code when I try to marry Moose and DBIx::DataModel. Moose metaclass programming is indeed very powerful, that with it, I simply tried to hack away this code in my few days of vacation time. This will certainly be useful me and I hope others will find it useful as well.

This project aims to be a clean and practical object-relational persistence solution. I acknowledge that we are standing on the shoulders of giants. Concepts and API were inspired by Django's ORM and DBIx::DataModel. Internally, we are using SQL::Abstract and DBIx::Simple as helpers. For now, we are using string-substitution as the strategy for SQL generation. 

It also does not implement Martin Fowler's DataMapper pattern (P of EAA). Data::CapabilityBased seems to be next evolution towards a true DataMapper. We are not implementing the Identity-Map or Unit-of-Work patterns either.

The current implementation is not yet perldoc documented (given the unstable API state). The tests will act as executable docs for now. See `t/*.t` and `t/*.pm` files for the mean time.


Copyright and License
---------------------

Copyright (c) 2010 by Dexter B. Tad-y

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


Disclaimer of Warranty
----------------------

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
