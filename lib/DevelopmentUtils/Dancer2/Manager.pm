package DevelopmentUtils::Dancer2::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Dancer2::Helper;

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

        $instance = new DevelopmentUtils::Dancer2::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Dancer2::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

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

sub _initHelper {

    my $self = shift;

    my $helper = DevelopmentUtils::Dancer2::Helper::getInstance(@_);
    if (!defined($helper)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Dancer2::Helper");
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
    'Install Dancer2',
    'Initialize new Dancer2 app',
    'Check for running Dancer2 app services',
    'Start Dancer2 app service',
    'Stop Dancer2 app service',
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

    if ($option eq 'Install Dancer2'){

        $self->{_helper}->install_dancer2();
    }
    elsif ($option eq 'Initialize new Dancer2 app'){

        $self->{_helper}->initialize_new_app();
    }
    elsif ($option eq 'Check for running Dancer2 app services'){

        $self->{_helper}->check_for_running_app_services();
    }
    elsif ($option eq 'Start Dancer2 app service'){

        $self->{_helper}->start_service();
    }
    elsif ($option eq 'Stop Dancer2 app service'){

        $self->{_helper}->stop_service();
    }
    elsif ($option eq 'Quit'){

        print "Bye\n";
        exit(0);
    }
    else {
        $self->{_logger}->logconfess("Unsupported option");
    }

    $self->_display_options();
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Dancer2::Manager

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Dancer2::Manager;
 my $manager = DevelopmentUtils::Dancer2::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut