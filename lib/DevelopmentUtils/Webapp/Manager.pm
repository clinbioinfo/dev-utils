package DevelopmentUtils::Webapp::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use Proc::ProcessTable;
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

use constant DEFAULT_SELENIUM_REMOTE_WEBDRIVER_PROCESS_NAME => 'selenium-server-standalone';

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

has 'selenium_remote_webdriver_process_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSeleniumRemoteWebdriverProcessName',
    reader   => 'getSeleniumRemoteWebdriverProcessName',
    required => FALSE,
    default  => DEFAULT_SELENIUM_REMOTE_WEBDRIVER_PROCESS_NAME
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

    if ($self->_is_selenium_remote_webdriver_running()){

        $self->{_webapp_install_checker}->runSmokeTests(@_);
    }
    else {
        printBoldRed("Selenium Remote Webdriver is NOT running.");
        exit(1);
    }
}

sub _is_selenium_remote_webdriver_running {

    my $self = shift;

    my $selenium_process_name = $self->getSeleniumRemoteWebdriverProcessName();

    my $process_table = new Proc::ProcessTable;
    if (!defined($process_table)){
        $self->{_logger}->logconfess("Could not instantiate Proc::ProcessTable");
    }

    foreach my $process (@{$process_table->table}){

        my $cmdline = $process->cmndline;
        if (!defined($cmdline)){
            $self->{_logger}->logconfess("cmdline was not defined for Process: ". Dumper $process);
        }

        if ($cmdline =~ m|$selenium_process_name|){

            $self->{_logger}->info("Looks like the Selenium Remote Webdriver process is running");

            printBrightBlue("Looks like the Selenium Remote Webdriver process is running");

            return TRUE;
        }
    }

    $self->{_logger}->error("Looks like Selenium Remote Webdriver process is not running");

    return FALSE;
}

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print  $msg . "\n";
    print color 'reset';
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
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
