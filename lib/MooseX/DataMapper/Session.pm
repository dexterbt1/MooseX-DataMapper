package MooseX::DataMapper::Session;
use strict;
use warnings;
use Moose;
use DBIx::Simple;
use Data::Dumper;
use SQL::Abstract::Limit;
use Scalar::Util qw/weaken/;
use Carp;

use MooseX::DataMapper::Meta;
use MooseX::DataMapper::QuerySet;
use MooseX::DataMapper::WorkUnit::Insert;
use MooseX::DataMapper::WorkUnit::Update;


has 'dbh' => (
    isa             => 'DBI::db',
    is              => 'rw',
    required        => 1,
    trigger         => sub {
        my ($self, $v) = @_;
        $v->ping
            or die "Unable to ping database handle: $DBI::errstr";
        $v->{RaiseError}
            or die "RaiseError is not set";
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
    isa             => 'ArrayRef[MooseX::DataMapper::WorkUnit]',
    is              => 'rw',
    default         => sub { [] },
);


sub save {
    my ($self, $i, $depth) = @_;
    if (scalar @_ == 2) { $depth=0; }
    eval {
        $self->save_deep($i, $depth);
    };
    if ($@) { croak $@; }
    $self->flush;
    return $i;
}

sub save_deep {
    my ($self, $i, $depth) = @_;
    # traverse object tree, saves the object graph, based on depth
    my $next_depth = (defined $depth) ? $depth-1 : undef;
    foreach my $i_fk_attr (@{$i->meta->foreignkey_attributes}) {
        my $i_fk_ref_to_attr = $i_fk_attr->ref_to_attr;
        my $i_fk_ref_from_attr = $i->meta->get_attribute($i_fk_attr->ref_from);
        my $i_fk = $i_fk_attr->get_value($i);
        if (defined($i_fk)) {
            if ( not(defined $next_depth) or ($next_depth >= 0) ) {
                $self->save_deep($i_fk, $next_depth);
            }
            # this will set the proper foreign key ids on the referred objects
            $i_fk_ref_from_attr->set_value($i, $i_fk_ref_to_attr->get_value($i_fk) );
        }
    }
    $self->save_one($i);
    return $i;
}


sub save_one {
    my ($self, $i) = @_;
    eval {
        if (defined $i->pk) {
            ($i->datamapper_session == $self)
                or croak "Cannot save a previously bound object into another session";
            # update
            MooseX::DataMapper::WorkUnit::Update->new( session => $self, target => $i )->execute;
        }
        else {
            # not pk yet, insert
            MooseX::DataMapper::WorkUnit::Insert->new( session => $self, target => $i )->execute;
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

sub objects {
    my ($self, @class_spec) = @_;
    return MooseX::DataMapper::QuerySet->new( session => $self, class_spec => \@class_spec );
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
