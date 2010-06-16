use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::DataMapper',
    license             => 'perl',
    dist_author         => 'Dexter B. Tad-y <dtady@cpan.org>',
    dist_version_from   => 'lib/MooseX/DataMapper.pm',
    build_requires => {
        'Test::More'                    => 0,
        'Moose'                         => 0,
        'SQL::Abstract'                 => 0,
        'SQL::Abstract::Limit'          => 0,
        'DBIx::Simple'                  => 0,
        'DBD::SQLite'                   => 0,
        'DateTime'                      => 0,
        'DateTime::Format::SQLite'      => 0,
        'DateTime::Format::MySQL'       => 0,
        'DateTime::Format::Pg',         => 0,
    },
    add_to_cleanup      => [ 'MooseX-DataMapper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
