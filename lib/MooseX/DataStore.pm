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


sub add {
    my $self = shift;
    foreach my $i (@_) {
        my $idmap_id = $self->get_idmap_id( $i->meta->name, $i->pk );
        if (defined($idmap_id) and not(exists $self->identity_map->{$idmap_id})) {
            weaken $i;
            $self->identity_map->{$idmap_id} = $i;
        }
        else {
            # not pk yet
            push @{$self->work_uncommitted}, 
                MooseX::DataStore::WorkUnit::Insert->new( datastore => $self, target => $i );
            $i->datastore( $self );
        }
    }
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
    return $o;
}


1;

__END__
