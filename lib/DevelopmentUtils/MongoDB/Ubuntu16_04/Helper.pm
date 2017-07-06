package DevelopmentUtils::MongoDB::Ubuntu16_04::Helper;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

extends 'DevelopmentUtils::MongoDB::Helper';

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => FALSE;

use constant DEFAULT_MONGODB_SERVICE_FILE => '/etc/systemd/system/mongodb.service';

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

# use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();
use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

my $systemctl_start_mongodb = 'sudo systemctl start mongodb';
my $systemctl_stop_mongodb = 'sudo systemctl stop mongodb';
my $systemctl_restart_mongodb = 'sudo systemctl restart mongodb';
my $systemctl_status_cmd = 'sudo systemctl status mongodb';
my $apt_update = 'sudo apt-get update';
my $apt_install_mongodb = 'sudo apt-get install -y mongodb';
my $enable_automatic_restart_cmd = 'sudo systemctl enable mongodb';

has 'mongodb_service_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setServiceFile',
    reader   => 'getServiceFile',
    required => FALSE,
    );

## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::MongoDB::Ubuntu16_04::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::MongoDB::Ubuntu16_04::Helper";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _check_if_installed {

    my $self = shift;

    ## Will check if MongoDB is installed by way of checking if the mongodb service is running.
    if ($self->_is_service_active()){

        print "The mongodb service is running\n";
        return TRUE;
    }
    
    print "The mongodb service is not running\n";
    
    return FALSE;
}

sub _is_service_active {

    my $self = shift;
 
    my $results = $self->_execute_cmd($systemctl_status_cmd);

    foreach my $line (@{$results}){

        if ($line =~ m|^\s*Active:\s+active\s+\(running\)|){

            $self->{_logger}->info("Looks like the mongodb service is active and running");

            return TRUE;
        }
    }

    $self->{_logger}->info("Looks like the mongodb service is not active and running");

    return FALSE; 
}

sub _check_service_status {

    my $self = shift;
 
    my $results = $self->_execute_cmd($systemctl_status_cmd);

    print join("\n", @{$results}) . "\n";
}

sub _install_mongodb {

    my $self = shift;

    if (! $self->_is_service_active()){

        $self->_execute_cmd($apt_update);

        $self->_execute_cmd($apt_install_mongodb);

        $self->_write_mongodb_service_file();

        $self->_start_service();
    }
    else {
        $self->{_logger}->warn("The MongoDB service is running");

        printYellow("The MongoDB service is currently running.  Will not attempt to install.");
    }
}


sub write_mongodb_service_file {

    my $self = shift;

    my $mongodb_service_file = $self->getServiceFile();
    if (!defined($mongodb_service_file)){
        $self->{_logger}->logconfess("mongodb_service_file was not defined");
    }
    
    if ($self->getTestMode()){
        printYellow("Running in test mode - would have created mongodb service file '$mongodb_service_file'");
    }
    else {

        my $temp_file = '/tmp/mongodb.service';

        open (OUTFILE, ">$temp_file") || $self->{_logger}->logconfess("Could not open '$temp_file' in write mode : $!");
        
        print OUTFILE "[Unit]\n";
        print OUTFILE "Description=High-performance, schema-free document-oriented database\n";
        print OUTFILE "After=network.target\n\n";

        print OUTFILE "[Service]\n";
        print OUTFILE "User=mongodb\n";
        print OUTFILE "ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf\n\n";

        print OUTFILE "[Install]\n";
        print OUTFILE "WantedBy=multi-user.target\n";

        close OUTFILE;

        $self->{_logger}->info("Wrote mongodb.service file '$temp_file'");   

        if (-e $mongodb_service_file){
            
            my $bakfile = $mongodb_service_file . '.' . time() . '.bak';

            my $cmd = "sudo mv $mongodb_service_file $bakfile";

            $self->_execute_cmd($cmd);
            
            $self->{_logger}->info("Moved '$mongodb_service_file' to '$bakfile'");
        }


        my $cmd = "sudo mv $temp_file $mongodb_service_file";

        $self->_execute_cmd($cmd);
    }
}

sub _enable_auto_start {

    my $self = shift;

    $self->_execute_cmd($enable_automatic_restart_cmd);
}
 
sub _start_service {

    my $self = shift;

    $self->_execute_cmd($systemctl_start_mongodb);
}

sub _stop_service {

    my $self = shift;
    
    $self->_execute_cmd($systemctl_stop_mongodb);
}

sub _restart_service {

    my $self = shift;
    
    $self->_execute_cmd($systemctl_restart_mongodb);
}

sub _execute_cmd {

    my $self = shift;    
    my ($ex) = @_;

    if ($self->getTestMode()){

        printYellow("Running in test mode - would have execute: '$ex'");
    }
    else {

        $self->{_logger}->info("About to execute '$ex'");

        printBrightBlue("\nAbout to execute '$ex'");

        my @results;

        eval {
            @results = qx($ex);
        };

        if ($?){
            $self->{_logger}->logconfess("Encountered some error while attempting to execute '$ex' : $! $@");
        }

        chomp @results;

        return \@results;
    }
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print $msg . "\n";
    print color 'reset';
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::MongoDB::Ubuntu16_04::Helper

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::MongoDB::Ubuntu16_04::Helper;
 my $manager = DevelopmentUtils::MongoDB::Ubuntu16_04::Helper::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut