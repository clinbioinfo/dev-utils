package DevelopmentUtils::Dancer2::Helper;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;
use Proc::ProcessTable;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => FALSE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

# use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();
use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

## Singleton support
my $instance;

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Dancer2::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Dancer2::Helper";
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

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub install_dancer2 {

    my $self = shift;

    my $cmd = "cpanm Dancer2";

    my $results = $self->_execute_cmd($cmd);

    print join("\n", @{$results}) . "\n";

}

sub initialize_new_app {

    my $self = shift;
    
    my $answer;

    while (1){

        print "Please provide the namespace for your new app : ";

        $answer = <STDIN>;

        chomp $answer;

        if (($answer =~ m|^\d|) || ($answer =~ m|^_|) || ($answer =~ m|^\:|)){

            printBoldRed("'$answer' is an invalid namespace");
        }
        else {
            last;
        }
    }

    my $tmpdir = $self->getOutdir();

    if (!-e $tmpdir){
    
        mkpath($tmpdir) || $self->{_logger}->logconfess("Could not create temporary directory '$tmpdir' : $!");
    
        $self->{_logger}->info("Created temporary directory '$tmpdir'");
    }

    chdir($tmpdir) || $self->{_logger}->logconfess("Could not change into temporary directory '$tmpdir' : $!");

    my $cmd = "dancer2 -a $answer";

    $self->_execute_cmd($cmd);

    my $subdir = $answer;

    $subdir =~ s|::|-|g;

    my $current_instance_dir = $tmpdir . '/' . $subdir;

    $self->{_current_instance_dir} = $current_instance_dir;

    printBrightBlue("The app has been initialized here:\n$current_instance_dir");
}

sub check_for_running_app_services {

    my $self = shift;

    my $table = new Proc::ProcessTable();
    if (!defined($table)){
        $self->{_logger}->logconfess("Could not instantiate Proc::ProcessTable");
    }

    my $count = 0;
    
    my $list = [];

    foreach my $process (@{$table->table}){

        my $state = $process->state;
        
        my $cmd = $process->cmndline;

        if ($cmd =~ m|plackup|){
        
            push(@{$list}, [$state, $cmd]);
        
            $count++;
        }
    }

    if ($count > 0){

        if ($count == 1){
            printBrightBlue("Looks like there is one instance of a Dancer2 app running on this machine:");
        }
        else {
            printBrightBlue("Looks like there are the following '$count' instances of Dancer2 apps running on this machine:");
        }

        foreach my $set (@{$list}){
            print "state '$set->[0]' command '$set->[1]'\n";
        }    
    }
    else {

        printYellow("Looks like there are no instances of Dancer2 apps running on this machine.");        
    }
}

sub start_service {

    my $self = shift;

    my $answer;

    while (1){

        print "Please provide the port number (default is 5000) : ";

        $answer = <STDIN>;

        chomp $answer;

        if ($answer eq ''){
            $answer = 5000;
            last;
        }
        elsif ($answer !~ m|^\d+$|){

            printBoldRed("'$answer' is not a valid port number");
        }
        else {
            last;
        }
    }

    my $stdout = $self->getOutdir() . '/app.psgi.stdout';
    my $stderr = $self->getOutdir() . '/app.psgi.stderr';
   
    my $cmd = "plackup -r bin/app.psgi -p $answer 1>$stdout 2>$stderr";

    if (exists $self->{_current_instance_dir}){

        if (-e $self->{_current_instance_dir}){
        
            chdir($self->{_current_instance_dir}) || $self->{_logger}->logconfess("Could not change into Dancer2 app instance directory '$self->{_current_instance_dir}' : $!");

            printBrightBlue("Change into your Dancer2 app instance directory '$self->{_current_instance_dir}' and then execute:\n$cmd\n");
        }
        else {
            $self->{_logger}->logconfess("Dancer2 app instance directory '$self->{_current_instance_dir}' does not exist");
        }
    }
    else {
        printBrightBlue("Change into your Dancer2 app instance directory and then execute:\n$cmd\n");
    }
}

sub stop_service {

    my $self = shift;

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
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

 DevelopmentUtils::Dancer2::Helper

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Dancer2::Helper;
 my $helper = DevelopmentUtils::Dancer2::Helper::getInstance();
 $helper->install_dancer2();
 $helper->initialize_new_app();
 $helper->check_for_running_app_services();
 $helper->start_service();
 $helper->stop_service();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut