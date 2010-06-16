MooseX::DataMapper
==================

An object-relational mapper for persisting / querying Moose-based objects in SQL relational databases.

WARNING
-------

This is experimental / preview stuff and the API and implementaion is still highly fluid and is continuously evolving. This is not (yet) even packaged for / released in CPAN. Even the project name may later. Standard full disclaimer below. USE AT YOUR OWN RISK!


Features (so far)
-----------------
* Basic single-table CRUD
* Chainable DSL-like query API
* Support for ForeignKey with assocation (reverse) link
* Custom ColumnHandlers for inflation/deflation of more complex objects


TODO / Upcoming:
----------------

* Custom Columns / Aggregation
* Order-by / Group-By
* Lazy-loaded fields
* Joins


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

Why yet another ORM? This project stemmed from getting tired of all my duplicated mapping when I try to marry Moose and DBIx::DataModel. Moose metaclass programming is indeed very powerful, that I simply tried to hack away this code in my few days of vacation free time.

This project aims to be practical Moose-friendly persistence solution. I acknowledge that we are standing standing on the shoulders of giants. Concepts and API were inspired from Django's ORM and DBIx::DataModel. It internally uses SQL::Abstract and DBIx::Simple as helpers and for now uses string-substitution as the strategy for SQL generation. 

It also does not (yet?) implement Martin Fowler's DataMapper pattern (P of EAA). Data::CapabilityBased seems to be the No Identity Map or Unit-of-Work patterns either.

The current implementation is not yet perldoc documented (given the unstable API state). The tests will act as executable docs for now. See `t/*.t` and `t/*.pm` files for the mean time.


Copyright and License
---------------------

Copyright (c) 2010 by Dexter B. Tad-y

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


Disclaimer of Warranty
----------------------

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
