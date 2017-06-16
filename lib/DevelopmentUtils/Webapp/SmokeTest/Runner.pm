package DevelopmentUtils::Webapp::SmokeTest::Runner;

use Moose;
use Cwd;
use Try::Tiny;
use Term::ANSIColor;
use Selenium::Remote::Driver;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_WAIT => 10;

use constant DEFAULT_MAX_SEARCH_ATTEMPTS_COUNT => 3;

use constant DEFAULT_BROWSER_NAME => 'chrome';

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

## Singleton support
my $instance;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

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

has 'url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setURL',
    reader   => 'getURL',
    required => FALSE
    );

has 'wait' => (
    is       => 'rw',
    isa      => 'Int',
    writer   => 'setWait',
    reader   => 'getWait',
    required => FALSE,
    default  => DEFAULT_WAIT
    );

has 'target_xpath' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTargetXpath',
    reader   => 'getTargetXpath',
    required => FALSE
    );

has 'browser_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setBrowserName',
    reader   => 'getBrowserName',
    required => FALSE,
    default  => DEFAULT_BROWSER_NAME
    );

has 'max_search_attempts_count' => (
    is       => 'rw',
    isa      => 'Int',
    writer   => 'setMaxSearchAttemptsCount',
    reader   => 'getMaxSearchAttemptsCount',
    required => FALSE,
    default  => DEFAULT_MAX_SEARCH_ATTEMPTS_COUNT
    );

has 'status' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setStatus',
    reader   => 'getStatus',
    required => FALSE
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Webapp::SmokeTest::Runner(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Webapp::SmokeTest::Runner";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initSeleniumRemoteDriver(@_);

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

sub _initSeleniumRemoteDriver {

    my $self = shift;

    my $browser_name = $self->getBrowserName();
    if (!defined($browser_name)){
        $self->{_logger}->logconfess("browser_name was not defined");
    }

    my $driver = new Selenium::Remote::Driver(browser_name => $browser_name);
    if (!defined($driver)){
        $self->{_logger}->logconfess("Could not instantiate Selenium::Remote::Driver");
    }

   $self->{_driver} = $driver;
}

sub run {

    my $self = shift;

    my $url = $self->getURL();
    if (!defined($url)){
        $self->{_logger}->logconfess("url was not defined");
    }

    my $wait = $self->getWait();
    if (!defined($wait)){
        $self->{_logger}->logconfess("wait was not defined");
    }

    my $target_xpath = $self->getTargetXpath();
    if (!defined($target_xpath)){
        $self->{_logger}->logconfess("target_xpath was not defined");
    }


    if ($self->getVerbose()){
        print "Will attempt to get the URL\n";
    }
    
    $self->{_driver}->get($url);

    # my $title = $self->{_driver}->get_title();
    # if (!defined($title)){
    #     $self->{_logger}->logconfess("title was not defined");
    # }

    # print "Found page title '$title'\n";

    my $search_attempt_ctr = 0;

    my $milliseconds = $wait * 1000;

    $self->{_logger}->info("Setting implicit wait timeout to '$milliseconds' milliseconds");

    $self->{_driver}->set_implicit_wait_timeout($milliseconds);


    while (1){

        my $xpath;

        try {
            
            $xpath = $self->{_driver}->find_element($target_xpath);

        } catch {

            $self->{_logger}->error("Encountered some error while attempting to find element '$target_xpath' : $_");
            
            printBoldRed("Encountered some error while attempting to find element '$target_xpath' : $_");
            
            $self->setStatus('unsuccessful');
            
            last;
        };

        if (!defined($xpath)){
            
            $self->{_logger}->warn("Could not find element for target_xpath '$target_xpath'.  Will wait '$wait' seconds.");
            
            sleep($wait);
        }
        else {

            $self->{_logger}->info("Found element for target_xpath '$target_xpath'");
            
            $self->setStatus('successful');

            last;
        }


        $search_attempt_ctr++;

        if ($search_attempt_ctr > $self->getMaxSearchAttemptsCount()){
            
            $self->{_logger}->error("Could not find the element for target_xpath '$target_xpath' after '$search_attempt_ctr' search attempts");
            
            $self->setStatus('unsuccessful');

            last;
        }
    }
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


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Webapp::SmokeTest::Runner
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Webapp::SmokeTest::Runner;
 my $manager = DevelopmentUtils::Webapp::SmokeTest::Runner::getInstance();
 $manager->runSmokeTests();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
