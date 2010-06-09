package MooseX::DataStore;
use strict;
use warnings;
use Moose;
use DBIx::Simple;
use SQL::Abstract::Limit;
use Scalar::Util qw/weaken/;
use Carp;

use MooseX::DataStore::Meta;
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
    isa             => 'HashRef[Str]',
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
        my $idmap_id = $self->get_idmap_id( $i );
        if (defined($idmap_id) and not(exists $self->identity_map->{$idmap_id})) {
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


sub find {
}


# ============================


sub get_idmap_id {
    my ($self, $i) = @_;
    my $pk = $i->pk;
    return if (not defined $pk);
    sprintf("%s-%d-%d", $i->meta->name, $$, $i->pk);
}


1;

__END__
