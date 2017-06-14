package DevelopmentUtils::Projects::Manager;

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
use DevelopmentUtils::Git::Manager;

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

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Projects::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Projects::Manager";
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

sub _initGitManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Manager");
    }

    $self->{_git_manager} = $manager;
}

sub run {

    my $self = shift;

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");

    $self->_analyze_project_dir();
    $self->_display_findings();
}

sub _analyze_project_dir {

    my $self = shift;
    
    my $cmd = "find $self->{_project_dir} -maxdepth 1 -type d";

    my $results = $self->_execute_cmd($cmd);

    foreach my $project_dir (@{$results}){

        my $subdir = $self->{_project_dir} . '/' . $project_dir;

        if (!-e $subdir){
            $self->{_logger}->logconfess("project directory '$subdir' does not exist");
        }

        if (!-d $subdir){
            $self->{_logger}->logconfess("'$subdir' is not a regular directory");
        }

        $self->_analyze_subdirectory($subdir, $project_dir);
    }
}

sub _analyze_subdirectory {

    my $self = shift;
    my ($subdir, $project_dir) = @_;

    my $cmd = "find $subdir -maxdepth 1 -type d";

    my $results = $self->_execute_cmd($cmd);

    foreach my $project_subdir (@{$results}){

        my $subdir = $self->{_project_dir} . '/' . $project_dir;

        if (!-e $subdir){
            $self->{_logger}->logconfess("project directory '$subdir' does not exist");
        }

        if (!-d $subdir){
            $self->{_logger}->logconfess("'$subdir' is not a regular directory");
        }

        $self->_analyze_subdirectory($subdir);
    }


}


sub _display_findings {

    my $self = shift;
    
    print "Found the following '$self->{_project_dir_count}' project directories under '$self->{_project_dir}'\n";

}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;
    
    my @results;
 
    $self->{_logger}->info("About to execute '$cmd'");
    
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

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Projects::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Projects::Manager;
 my $manager = DevelopmentUtils::Projects::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
