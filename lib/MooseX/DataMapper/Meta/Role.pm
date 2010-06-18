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
    my $pk_spec = $self->meta->primary_key;
    if (ref($pk_spec) eq 'ARRAY') {
        my $out = { };
        foreach my $pk_attr (@$pk_spec) {
            my $val = $pk_attr->get_value($self);
            if (not defined $val) {
                undef $out;
                last;
            }
            $out->{$pk_attr->name} = $val;
        }
        return $out;
    }
    return $pk_spec->get_value($self);
}

sub DESTROY {
    my ($self) = @_;
    delete $session_of->{"$self"};
}

1;

__END__
