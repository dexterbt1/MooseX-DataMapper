package MooseX::DataMapper::Meta::Role;
use strict;
use Moose::Role;
use Carp;

# inside-out 
my $session_of = { };
sub datamapper_session {
    my $self = shift @_;
    if (@_) {
        $session_of->{"$self"} = shift @_;
    }
    return $session_of->{"$self"};
}

sub pk {
    my $self = shift @_;
    my $pk_attr = $self->meta->primary_key;
    return $pk_attr->get_value($self);
}

sub DESTROY {
    my ($self) = @_;
    delete $session_of->{"$self"};
}

1;

__END__
