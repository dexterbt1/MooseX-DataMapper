package MooseX::DataMapper::ColumnHandlers::DateTime;
use strict;
# can be refactored later to be lazily loaded
use DateTime;
use DateTime::Format::SQLite;
use DateTime::Format::Pg;
use DateTime::Format::MySQL;

require Exporter;
our @ISA = qw/Exporter/;

our @EXPORT_OK = qw/
    from_date               to_date
    from_time               to_time
    from_datetime           to_datetime
    from_year               to_year
/;

# =========================

sub _to_date { 
    my ($db_val, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $db_val) ? $class->parse_date($db_val) : $db_val;
}
sub to_date { return \&_to_date; }



sub _from_date { 
    my ($dt, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $dt) ? $class->format_date($dt) : $dt;
}
sub from_date { return \&_from_date; }


# =========================

sub _to_time { 
    my ($db_val, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $db_val) ? $class->parse_time($db_val) : $db_val;
}
sub to_time { return \&_to_time; }



sub _from_time { 
    my ($dt, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $dt) ? $class->format_time($dt) : $dt;
}
sub from_time { return \&_from_time; }


# =========================

sub _to_datetime { 
    my ($db_val, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $db_val) ? $class->parse_datetime($db_val) : $db_val;
}
sub to_datetime { return \&_to_datetime; }



sub _from_datetime { 
    my ($dt, $driver) = @_; my $class = "DateTime::Format::$driver"; 
    (defined $dt) ? $class->format_datetime($dt) : $dt;
}
sub from_datetime { return \&_from_datetime; }


# =========================


sub _to_year { (defined $_[0]) ? DateTime->new(year => $_[0]) : $_[0]; }
sub to_year { return \&_to_year; }

sub _from_year { (defined $_[0]) ? $_[0]->year : $_[0]; }
sub from_year { return \&_from_year; }


1;

__END__
