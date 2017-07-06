package DevelopmentUtils::MongoDB::Helper;

use Moose;
use Term::ANSIColor;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

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

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::MongoDB::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::MongoDB::Helper";
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

sub _check_if_installed {

    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
}

sub _install_mongodb {

    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
}

sub _enable_auto_start {

    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
}

sub _check_service_status {
    
    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
}
 
sub _start_service {

    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
}

sub _stop_service {

    my $self = shift;

    $self->{_logger}->logconfess("Abstract method - you must implement this method in your base class.");
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

 DevelopmentUtils::MongoDB::Helper

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::MongoDB::Helper;
 my $manager = DevelopmentUtils::MongoDB::Helper::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut