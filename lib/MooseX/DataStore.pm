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
use MooseX::DataStore::WorkUnit::CodeHook;
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

has 'work_unflushed' => (
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
    my ($self, $i, $depth) = @_;
    if (scalar @_ == 2) { $depth=0; }
    $self->save_deep($i, $depth);
    $self->flush;
    return $i;
}

sub save_deep {
    my ($self, $i, $depth) = @_;
    # traverse object tree, saves the object graph, based on depth
    my $next_depth = (defined $depth) ? $depth-1 : undef;
    foreach my $i_fk_attr (@{$i->meta->foreignkey_attributes}) {
        my $i_fk_ref_to_attr_name = $i_fk_attr->ref_to_attr->name;
        my $i_fk_ref_from = $i_fk_attr->ref_from;
        my $i_fk_attr_name = $i_fk_attr->name;
        my $i_fk = $i->$i_fk_attr_name;
        if (defined($i_fk)) {
            if ( not(defined $next_depth) or ($next_depth > 0) ) {
                $self->save_deep($i_fk, $next_depth);
            }
            # this will set the proper foreign key ids on the referred objects
            $i->$i_fk_ref_from( $i_fk->$i_fk_ref_to_attr_name );
        }
    }
    $self->save_one($i);
    return $i;
}


sub save_one {
    my ($self, $i) = @_;
    eval {
        if (defined $i->pk) {
            # update
            MooseX::DataStore::WorkUnit::Update->new( datastore => $self, target => $i )->execute;
        }
        else {
            # not pk yet, insert
            $i->datastore( $self );
            MooseX::DataStore::WorkUnit::Insert->new( datastore => $self, target => $i )->execute;
        }
    };
    if ($@) { croak $@; }
    return $i;
}


sub flush {
    my ($self) = @_;
    while (my $work = shift @{$self->work_unflushed}) {
        $work->execute;
    }
}

sub find {
    my ($self, @class_spec) = @_;
    return MooseX::DataStore::QuerySet->new( datastore => $self, class_spec => \@class_spec );
}


# ============================


sub enqueue_work {
    my ($self, $work) = @_;
    push @{$self->work_unflushed}, $work;
}


sub DEMOLISH {
    my ($self) = @_;
    $self->flush;
}


1;

__END__
