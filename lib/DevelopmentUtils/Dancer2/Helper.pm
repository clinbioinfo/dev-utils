package DevelopmentUtils::Dancer2::Helper;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;

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

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub initialize_new_app {

    my $self = shift;
    
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub check_for_running_app_services {

    my $self = shift;
 
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub start_service {

    my $self = shift;

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
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