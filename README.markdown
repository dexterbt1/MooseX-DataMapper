MooseX::DataMapper
==================

An object-relational mapper for persisting / querying Moose-based objects in SQL relational databases.

WARNING
-------

This is experimental / preview stuff and the API and implementaion is still highly fluid and is continuously evolving. This is not (yet) even packaged for / released in CPAN. Standard full disclaimer below.


Features (so far)
-----------------
* Basic single-table CRUD
* Chainable DSL-like query API
* Support for ForeignKey with assocation (reverse) link


TODO / Upcoming:
----------------

* Lazy-loaded fields
* Order-by / Group-By
* Aggregation
* Joins


Requirements
------------

* Moose
* SQL::Abstract
* SQL::Abstract::Limit
* DBIx::Simple
* DBD::SQLite


Notes
-----

Why yet another ORM? I acknowledge that we are standing standing on the shoulders of giants. Moose metaclass programming is indeed very powerful, so much as to learn more about it, I hacked away this code in my few days of vacation free time. This project aims to be practical Moose-friendly persistence solution in the future.

This project borrows from concepts and API of mostly DBIx::DataModel and Django ORM, but not on the Ruby-based DataMapper project. It also tries to reuse SQL::Abstract and DBIx::Simple internally. I am surprised to see that it kind of mirrors the DBIx::Class API although I have zero experience with it.

It also does not (yet?) implement Martin Fowler's DataMapper pattern (P of EAA). No Identity Map or Unit-of-Work patterns either.

The current implementation is not yet perldoc documented (given the unstable API state). The tests will act as executable docs for now. See `t/*.t` and `t/*.pm` files for the mean time.


Copyright and License
---------------------

Copyright (c) 2010 by Dexter B. Tad-y

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


Disclaimer of Warranty
----------------------

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
