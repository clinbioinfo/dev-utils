package DevelopmentUtils::Webapp::Install::Checker;

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
use DevelopmentUtils::Webapp::Config::Manager;
use DevelopmentUtils::Webapp::SmokeTest::Runner;

use constant TRUE  => 1;
use constant FALSE => 0;

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

        $instance = new DevelopmentUtils::Webapp::Install::Checker(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Webapp::Install::Checker";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initWebappConfigManager(@_);

    $self->_load_project_lookup();

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

sub _initWebappConfigManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Webapp::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Webapp::Config::Manager");
    }

    $self->{_webapp_config_manager} = $manager;
}

sub _load_project_lookup {

    my $self = shift;
    
    my $lookup = $self->{_webapp_config_manager}->getWebappInstallLookup();
    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined");
    }

    $self->{_project_lookup} = $lookup;

    $self->{_logger}->info("Loaded project lookup");
}

sub runSmokeTests {

    my $self = shift;

    $self->{_project_ctr} = 0;
    $self->{_successful_ctr} = 0;
    $self->{_unsuccessful_ctr} = 0;

    my $lookup = $self->{_project_lookup};

    foreach my $project (sort keys %{$lookup}){

        $self->{_project_ctr}++;

        my $url = $lookup->{$project}->{url};
        my $name = $lookup->{$project}->{name};
        my $desc = $lookup->{$project}->{desc};
        my $wait = $lookup->{$project}->{wait};
        my $target_xpath = $lookup->{$project}->{target_xpath};

        if ($self->getVerbose()){

            printYellow("Processing project '$project'");
            print "\tname: '$name'\n";
            print "\tdesc: '$desc'\n";
            print "\twait: '$wait'\n";
            print "\ttarget xpath: '$target_xpath'\n";
            print "\tURL: '$url'\n";
        }

        $self->{_logger}->info("project '$project'");
        $self->{_logger}->info("name '$name'");
        $self->{_logger}->info("desc '$desc'");
        $self->{_logger}->info("wait '$wait'");
        $self->{_logger}->info("target_xpath '$target_xpath'");
        $self->{_logger}->info("url '$url'");


        my $runner = new DevelopmentUtils::Webapp::SmokeTest::Runner(
            url => $url,
            wait => $wait,
            target_xpath => $target_xpath
            );

        if (!defined($runner)){
            $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Webapp::SmokeTest::Runner");
        }

        print "Running smoke test now...\n";

        $runner->run();

        my $status = $runner->getStatus();
        if (!defined($status)){
            $self->{_logger}->logconfess("status was not defined");
        }

        # $lookup->{$project}->{status} = $status;

        if ($status eq 'successful'){
            push(@{$self->{_successful_lookup}}, $project);
            $self->{_successful_ctr}++;
        }
        else {
             push(@{$self->{_unsuccessful_lookup}}, $project);
            $self->{_unsuccessful_ctr}++;   
        }

    }

    $self->_generate_report();
}


sub _generate_report {

    my $self = shift;

    print "Processed '$self->{_project_ctr}' projects\n";

    if ($self->{_successful_ctr} > 0){
        
        printGreen("Checks for the following '$self->{_successful_ctr}' projects were successful");
        
        foreach my $project (sort keys %{$self->{_successful_lookup}}){
        
            my $name = $self->{_project_lookup}->{$project}->{name};
        
            my $url = $self->{_project_lookup}->{$project}->{url};
        
            print "$project ($name)\n";
        
            print "\t$url\n";        
        }
    }

    if ($self->{_unsuccessful_ctr} > 0){
        
        printBoldRed("Checks for the following '$self->{_unsuccessful_ctr}' projects were unsuccessful");
        
        foreach my $project (sort keys %{$self->{_unsuccessful_lookup}}){
        
            my $name = $self->{_project_lookup}->{$project}->{name};
        
            my $url = $self->{_project_lookup}->{$project}->{url};
        
            print "$project ($name)\n";
        
            print "\t$url\n";        
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

 DevelopmentUtils::Webapp::Install::Checker
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Webapp::Install::Checker;
 my $manager = DevelopmentUtils::Webapp::Install::Checker::getInstance();
 $manager->runSmokeTests();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
