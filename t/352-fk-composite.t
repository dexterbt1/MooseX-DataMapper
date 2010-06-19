use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'DBI';
    use_ok 'MooseX::DataMapper';
}

{
    package Employee;
    use MooseX::DataMapper;
    use Moose -traits => qw/DataMapper::Class/;

    has 'name' => (
        traits              => [qw/Persistent/],
        isa                 => 'Str',
        is                  => 'rw',
        required            => 1,
    );

    has 'ssn' => (
        traits              => [qw/Persistent/],
        isa                 => 'Int',
        is                  => 'rw',
        required            => 1,
    );

    has 'salary' => (
        traits              => [qw/Persistent/],
        isa                 => 'Int',
        is                  => 'rw',
    );

    __PACKAGE__->meta->datamapper_class_setup(
        -table              => 'employee',
        -primary_key_type   => 'Composite',
        -primary_key        => [ 'name', 'ssn' ],
        
    );

    package LeaveCredit;
    use MooseX::DataMapper;
    use Moose -traits => qw/DataMapper::Class/;

    has 'employee_name' => (
        traits              => [qw/Persistent/],
        isa                 => 'Str',
        is                  => 'rw',
        column              => 'emp_name',
    );

    has 'employee_ssn' => (
        traits              => [qw/Persistent/],
        isa                 => 'Int',
        is                  => 'rw',
        column              => 'emp_ssn',
    );

    has 'annual_vacation_days' => (
        traits              => [qw/Persistent/],
        isa                 => 'Int',
        is                  => 'rw',
    );

#    has 'employee'          => (
#        traits              => [qw/ForeignKey/],
#        ref_from            => [qw/employee_name employee_ssn/],
#        ref_to              => [qw/LeaveCredit name ssn/],
#        association_link    => 'leave_credits',
#        isa                 => 'Employee',
#        is                  => 'rw',
#    );

    __PACKAGE__->meta->datamapper_class_setup(
        -table              => 'leave_credit',
        -auto_pk            => 'id',
    );
    
    
}


# --------------- in database operations


my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1 });
$dbh->do(<<"EOT");
    CREATE TABLE employee (id INTEGER PRIMARY KEY AUTOINCREMENT, company_id INTEGER REFERENCES point (id), name VARCHAR, bio BLOB);
EOT


my $ds = MooseX::DataMapper->connect($dbh);
$ds->debug(1);


ok 1;


__END__
