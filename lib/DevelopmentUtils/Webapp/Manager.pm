package DevelopmentUtils::Webapp::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'json_file_to_perl';

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Webapp::Install::Checker;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

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
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'webapp_install_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setWebappConfigFile',
    reader   => 'getWebappConfigFile',
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

        $instance = new DevelopmentUtils::Webapp::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Webapp::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initWebappInstallChecker(@_);

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

sub _initWebappInstallChecker {

    my $self = shift;

    my $checker = DevelopmentUtils::Webapp::Install::Checker::getInstance(@_);
    if (!defined($checker)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Webapp::Install::Checker");
    }

    $self->{_webapp_install_checker} = $checker;
}

sub runSmokeTests {

    my $self = shift;

    $self->{_webapp_install_checker}->runSmokeTests(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Webapp::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Webapp::Manager;
 my $manager = DevelopmentUtils::Webapp::Manager::getInstance();
 $manager->runSmokeTests();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
