package DevelopmentUtils::MongoDB::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::MongoDB::Helper::Factory;

use constant TRUE  => 1;
use constant FALSE => 0;

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

        $instance = new DevelopmentUtils::MongoDB::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::MongoDB::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initHelperFactory(@_);

    $self->_initHelper(@_);

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

sub _initHelperFactory {

    my $self = shift;

    my $factory = DevelopmentUtils::MongoDB::Helper::Factory::getInstance(@_);
    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::MongoDB::Helper::Factory");
    }

    $self->{_helper_factory} = $factory;
}

sub _initHelper {

    my $self = shift;

    my $helper = $self->{_helper_factory}->create(@_);
    if (!defined($helper)){
        $self->{_logger}->logconfess("helper was not defined");
    }

    $self->{_helper} = $helper;
}

sub run {

    my $self = shift;
    
    $self->_display_options();
}

sub _display_options {

    my $self = shift;
 
    my $option_list = [
    'Check if MongoDB is installed',
    'Install MongoDB',
    'Enable auto-start',
    'Check status of MongoDB service',
    'Start MongoDB service',
    'Stop MongoDB service',
    'Quit'
    ];

    my $option_lookup = {};
    my $option_ctr = 0;

    print "\n\n";

    foreach my $option (@{$option_list}){

        $option_ctr++;

        $option_lookup->{$option_ctr} = $option;

        print $option_ctr . '. ' . $option . "\n";
    }


    my $answer;

    while (1){

        print "\nPlease choose an option : ";
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        if (exists $option_lookup->{$answer}){
        
            last;
        }
    }


    my $option = $option_lookup->{$answer};

    if ($option eq 'Check if MongoDB is installed'){

        $self->_check_if_installed();
    }
    elsif ($option eq 'Install MongoDB'){

        $self->_install_mongodb();
    }
    elsif ($option eq 'Enable auto-start'){

        $self->_enable_auto_start();
    }
    elsif ($option eq 'Check status of MongoDB service'){

        $self->_check_service_status
    }
    elsif ($option eq 'Start MongoDB service'){

        $self->_start_service();
    }
    elsif ($option eq 'Stop MongoDB service'){

        $self->_stop_service();
    }
    elsif ($option eq 'Quit'){

        print "Bye\n";
        exit(0);
    }
    else {
        $self->{_logger}->logconfess("Unsupported option");
    }
}

sub _check_if_installed {

    my $self = shift;

    $self->{_helper}->_check_if_installed();

    $self->_display_options();
}

sub _install_mongodb {

    my $self = shift;

    $self->{_helper}->_install_mongodb();
    
    $self->_display_options();
}

sub _enable_auto_start {

    my $self = shift;

    $self->{_helper}->_enable_auto_start();
    
    $self->_display_options();
}

sub _check_service_status {

    my $self = shift;

    $self->{_helper}->_check_service_status();
    
    $self->_display_options();
}

sub _start_service {

    my $self = shift;

    $self->{_helper}->_start_service();
    
    $self->_display_options();
}
sub _stop_service {

    my $self = shift;

    $self->{_helper}->_stop_service();
    
    $self->_display_options();
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::MongoDB::Manager

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::MongoDB::Manager;
 my $manager = DevelopmentUtils::MongoDB::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut