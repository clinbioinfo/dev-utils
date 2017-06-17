package DevelopmentUtils::Perlbrew::Helper;

use Moose;
use Cwd;
use Try::Tiny;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";


## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigFile',
    reader   => 'getConfigFile',
    required => FALSE,
    default  => DEFAULT_CONFIG_FILE
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Perlbrew::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Perlbrew::Helper";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_load_options_lookup();

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


sub run {

    my $self = shift;

    print "\n\n";

    $self->_display_options();
    
    $self->_prompt_user();
    
}

sub _load_options_lookup {

    my $self = shift;

    $self->{_options_lookup} = {
        1 => 'Display current settings',
        2 => 'List available versions and virtual environments',
        3 => 'Create virtual environment'
    };
}


sub _display_options {

    my $self = shift;

    print "Here are your options:\n";

    foreach my $num (sort {$a <=> $b} keys %{$self->{_options_lookup}}){
        
        my $option = $self->{_options_lookup}->{$num};
        
        print $num . '. ' . $option . "\n";
    }
}


sub _prompt_user {

    my $self = shift;
  
    my $answer;

    while (1) {

        print "Please make a selection [q]: ";    
        
        $answer = <STDIN>;
        
        chomp $answer;
                
        if ((!defined($answer)) || ($answer eq '')){
            next;
        }
        elsif (uc($answer) eq 'Q'){

            print color 'bold red';
            print "Umm, okay- bye!\n";
            print color 'reset';

            exit(1);
        }
        elsif ($answer == int($answer)){
            if (exists $self->{_options_lookup}->{$answer}){
                last
            }
        }
    }

    my $option = $self->{_options_lookup}->{$answer};

    print "Will execute option '$option'\n";


    if ($answer == 1){
        $self->_display_current_settings();
    }
    elsif ($answer == 2){
        $self->_list_versions_of_perl();
    }
    elsif ($answer ==3 ){
        $self->_create_virtual_libary(); 
    }
    else {
        $self->{_logger}->logconfess("Unexpected value '$answer'");
    }
}


sub _display_current_settings {

    my $self = shift;

    my $cmd = "perlbrew info";
    
    my $results = $self->_execute_cmd($cmd);
    
    printBrightBlue("Here are the current details:");
        
    foreach my $line (@{$results}){
    
        print "$line\n";
    }

    $self->run();
}

sub _list_versions_of_perl {

    my $self = shift;

    my $cmd = "perlbrew list";
    
    my $results = $self->_execute_cmd($cmd);
    
    printBrightBlue("Here are the available versions of Perl:");
    
    my $ctr = 0;
    
    foreach my $version (@{$results}){
    
        $ctr++;
    
        print "$ctr. " . $version . "\n";
    }

    $self->run();
}

sub _create_virtual_libary {

    my $self = shift;

    printYellow("NOT YET IMPLEMENTED");

    $self->run();
}



sub _execute_cmd {

    my $self = shift;

    my ($cmd) = @_;
    
    if (!defined($cmd)){
        $self->{_logger}->logconfess("cmd was not defined");
    }

    $self->{_logger}->info("About to execute '$cmd'");

    my @results;

    eval {
        @results = qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @results;

    return \@results;
}    

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
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

 DevelopmentUtils::Perlbrew::Helper
 A module for executing set of tasks at end-of-business-day. 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Perlbrew::Helper;
 my $manager = DevelopmentUtils::Perlbrew::Helper::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
