package MooseX::DataStore;
use strict;
use warnings;
use Moose;
use DBIx::Simple;
use SQL::Abstract::Limit;
use Scalar::Util qw/weaken/;
use Carp;

use MooseX::DataStore::Meta;
use MooseX::DataStore::QuerySet;
use MooseX::DataStore::WorkUnit::Insert;
use MooseX::DataStore::WorkUnit::Update;


has 'dbh' => (
    isa             => 'DBI::db',
    is              => 'rw',
    trigger         => sub {
        my ($self, $v) = @_;
        $v->ping
            or die "Unable to ping database handle: $DBI::errstr";
        $self->sqlabs( SQL::Abstract::Limit->new( limit_dialect => $v ) );
        $self->dbixs( DBIx::Simple->connect( $v ) );
    },
);

has 'sqlabs' => (
    isa             => 'SQL::Abstract',
    is              => 'rw',
);

has 'dbixs' => (
    isa             => "DBIx::Simple",
    is              => 'rw',
);

has 'identity_map' => (
    isa             => 'HashRef[MooseX::DataStore::Meta::Class::Trait::DataObject]',
    is              => 'rw',
    default         => sub { {} },
);

has 'work_uncommitted' => (
    isa             => 'ArrayRef[MooseX::DataStore::WorkUnit]',
    is              => 'rw',
    default         => sub { [] },
);


sub connect {
    my $class = shift @_;
    my $self = $class->new;
    if (blessed($_[0]) and $_[0]->isa('DBI::db')) {
        $self->dbh($_[0]);        
    }
    return $self;
}


sub save {
    my ($self, $i) = @_;
    if (defined $i->pk) {
        # update
        push @{$self->work_uncommitted},
            MooseX::DataStore::WorkUnit::Update->new( datastore => $self, target => $i );
    }
    else {
        # not pk yet, insert
        push @{$self->work_uncommitted}, 
            MooseX::DataStore::WorkUnit::Insert->new( datastore => $self, target => $i );
        $i->datastore( $self );
    }
    return $self;
}


sub flush {
    my ($self) = @_;
    while (my $work = shift @{$self->work_uncommitted}) {
        $work->execute;
    }
}


sub commit {
}


sub query {
    my ($self, @class_spec) = @_;
    return MooseX::DataStore::QuerySet->new( datastore => $self, class_spec => \@class_spec );
}


# ============================


sub get_idmap_id {
    my ($self, $class, $pk) = @_;
    return if (not defined $pk);
    return sprintf("%s{%d}", $class, $pk);
}

sub get_idmap_cached {
    my ($self, $class, $pk) = @_;
    my $idmap_id = $self->get_idmap_id( $class, $pk );
    return if (not defined $idmap_id);
    my $o = exists($self->identity_map->{$idmap_id}) ? $self->identity_map->{$idmap_id} : undef;
    return $o;
}

sub set_idmap_cached {
    my ($self, $class, $pk, $o) = @_;
    my $idmap_id = $self->get_idmap_id( $class, $pk );
    return if (not defined $idmap_id);
    $self->identity_map->{$idmap_id} = $o;
    weaken $self->identity_map->{$idmap_id};
    return $o;
}

sub DEMOLISH {
    my ($self) = @_;
    $self->flush;
}


1;

__END__
