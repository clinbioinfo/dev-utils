package DevelopmentUtils::Git::Helper;

use Moose;
use Try::Tiny;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'parse_json';
use JSON::Parse 'json_file_to_perl';
use JSON;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
# use DevelopmentUtils::Git::Branch::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

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
    writer   => 'setConfigFile',
    reader   => 'getConfigFile',
    required => FALSE,
    default  => DEFAULT_CONFIG_FILE
    );

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
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

## This is a JSON file listing all of the projects
## and their corresponding repo-url values.
has 'projects_conf_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProjectsConfFile',
    reader   => 'getProjectsConfFile',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Helper";
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

sub getProjectsLookup {

    my $self = shift;
    
    if (!exists $self->{_project_lookup}){

        my $file = $self->_get_projects_conf_file();

        if (!defined($file)){
            $self->{_logger}->logconfess("projects conf file was not defined");
        }


        if (!-e $file){
            $self->{_logger}->logconfess("project config JSON file '$file' does not exist");
        }

        my $lookup = json_file_to_perl($file);
        if (!defined($lookup)){
            $self->{_logger}->logconfess("lookup was not defined for file '$file'");
        }

        $self->{_project_lookup} = $lookup;
    }

    return $self->{_project_lookup};
}

sub _get_projects_conf_file {

    my $self = shift;
    
    my $file = $self->getProjectsConfFile();
    
    if (!defined($file)){

        $file = $self->{_config_manager}->getGitProjectsLookupFile();

        if (!defined($file)){
            $self->{_logger}->logconfess("file was not defined");
        }

        $self->setProjectsConfFile($file);
    }

    return $file;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 DevelopmentUtils::Git::Helper
 A module for retrieving branch information from remote git repository.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Helper;
 my $manager = DevelopmentUtils::Git::Helper::getInstance();
 $manager->getProjectsLookup();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
