package MooseX::DataMapper::Meta::Role;
use strict;
use Moose::Role;
use Carp;

# inside-out 
my $session_of = { };
sub datamapper_session {
    # this internal accessor actually additionally acts as an internal flag
    # whether an object is new vs. was fetched from the db
    my $self = shift @_;
    if (@_) {
        $session_of->{"$self"} = shift @_;
    }
    return $session_of->{"$self"};
}


# returns a single scalar value if a single key, otherwise a hashref
sub pk {
    my $self = shift @_;
    return $self->meta->primary_key->get_instance_value( $self );
}

sub DESTROY {
    my ($self) = @_;
    $self->meta->primary_key->cleanup_dirty($self);
    delete $session_of->{"$self"};
}

1;

__END__
