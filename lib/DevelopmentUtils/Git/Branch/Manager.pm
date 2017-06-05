package DevelopmentUtils::Git::Branch::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'parse_json';
use JSON::Parse 'json_file_to_perl';
use JSON;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

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

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
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

        $instance = new DevelopmentUtils::Git::Branch::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Branch::Manager";
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

sub getCurrentBranches {

    my $self = shift;

}

sub determineNextBranches {

    my $self = shift;

    return $self->recommendNextDevBranch(@_);
}

sub _print_banner {

    my $self = shift;
    my ($msg) = @_;

    print color 'yellow';
    print "************************************************************\n";
    print "*\n";
    print "* $msg\n";
    print "*\n";
    print "************************************************************\n";
    print color 'reset';
}

sub recommendNextDevBranch {

    my $self = shift;

    $self->{_logger}->info("NOT YET IMPLEMENTED");

    $self->_print_banner("Going to determine next development branches");

    $self->_load_project_lookup(@_);

    foreach my $project_name (sort keys %{$self->{_project_lookup}}){
        
        if ($self->getVerbose()){

            print "Processing project '$project_name'\n";
        }

        my $current_dev_branch = $self->_get_current_dev_branch($project_name);
        
        my $next_dev_branch = $self->_get_next_dev_branch($project_name);

        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        if ($self->getVerbose()){
            print "For project '$project_name'\n";
            print "Current dev branch '$current_dev_branch'\n";
            print "Recommended next dev branch '$next_dev_branch'\n";
            print "The repository URL is '$repo_url\n\n";
        }
    }

    $self->_generate_report();
}

sub _load_project_lookup {

    my $self = shift;
    
    my $file = $self->getProjectsConfFile();
    if (!-e $file){
        $self->{_logger}->logconfess("project config JSON file '$file' does not exist");
    }

    my $lookup = json_file_to_perl($file);
    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined for file '$file'");
    }

    $self->{_project_lookup} = $lookup;
}

sub _get_current_dev_branch {

    my $self = shift;
    my ($project_name) = @_;

    $self->_get_all_dev_branches($project_name);

    $self->_determine_current_and_next_branches($project_name);

    return $self->{_project_lookup}->{$project_name}->{current_dev_branch};
}

sub _get_next_dev_branch {

    my $self = shift;
    my ($project_name) = @_;

    return $self->{_project_lookup}->{$project_name}->{next_dev_branch};
}


sub _get_all_dev_branches {

    my $self = shift;
    my ($project_name) = @_;

    my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

    my $cmd = "git ls-remote --heads $repo_url";

    my $branch_list = $self->_execute_cmd($cmd);

    my $candidate_list = [];
    my $candidate_ctr = 0 ;

    if (scalar(@{$branch_list}) > 0){

        foreach my $line (@{$branch_list}){

            print "branch: $line\n";

            if ($line =~ m|^\S+\s+refs/heads/(\S+)\s*$|){

                my $candidate = $1;

                push(@{$candidate_list}, $candidate);

                $candidate_ctr++;
            }
        }
    }
    else {
        $self->{_logger}->logconfess("Did not find any branches for '$project_name' with repository URL '$repo_url'");
    }

    if ($self->getVerbose()){
        print "Found the following '$candidate_ctr' branches:\n";
        
        print join("\n", @{$candidate_list}) . "\n";
    }

    $self->{_project_lookup}->{$project_name}->{'branch-list'} = $candidate_list;

    $self->{_project_lookup}->{$project_name}->{'branch-count'} = $candidate_ctr;
}

sub _determine_current_and_next_branches {

    my $self = shift;
    my ($project_name) = @_;

    my $branch_list = $self->{_project_lookup}->{$project_name}->{'branch-list'};

    my $lookup = {};
    my $max_version = 0;
    my $max_revision = 0;
    
    foreach my $branch (@{$branch_list}){

        if ($self->getVerbose()){
            print "Processing branch '$branch'\n";
        }

        $branch =~ s|^\s+||;
        $branch =~ s|\s+$||;

        if ($branch eq 'HEAD'){
            next;
        }
        elsif ($branch eq 'master'){
            next;
        }
        elsif ($branch =~ m|v(\d+)r(\d+)\-dev\-branch$|){

            my $version = $1;

            my $revision = $2;

            if ($version > $max_version){
                $max_version = $version;
                $max_revision = 0;
            }

            if ($revision > $max_revision){
                $max_revision = $revision;
            }
            
            next;
        }
        elsif ($branch =~ m|v(\d+)\.(\d+)$|){

            my $version = $1;

            my $revision = $2;

            if ($version > $max_version){
                $max_version = $version;
                $max_revision = 0;
            }

            if ($revision > $max_revision){
                $max_revision = $revision;
            }

            next;
        }
        elsif ($branch =~ m|v(\d+)\.(\d+)\.(\d+)$|){

            my $version = $1;

            my $revision = $2;

            if ($version > $max_version){
                $max_version = $version;
                $max_revision = 0;
            }

            if ($revision > $max_revision){
                $max_revision = $revision;
            }

            next;
        }
        else {
            die "Unexpected branch '$branch' for project '$project_name'";
        }
    }

    my $current_dev_branch = 'v' . $max_version . '.' . $max_revision;

    $self->{_project_lookup}->{$project_name}->{current_dev_branch} = $current_dev_branch;   

    $max_revision++; ## increment for the next development branch
    
    my $next_dev_branch = 'v' . $max_version . '.' . $max_revision;

    $self->{_project_lookup}->{$project_name}->{next_dev_branch} = $next_dev_branch;
    
    if ($self->getVerbose()){

        print color 'green';
        print "For project '$project_name' - the next development branch should be '$next_dev_branch'\n";
        print color 'reset';
    }
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
	
sub _generate_report {

    my $self = shift;

    my $report_file = $self->getReportFile();

    open (OUTFILE, ">$report_file") || die "Could not open report file '$report_file' in write mode : $!";

    print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
    print OUTFILE "## date-created: " . localtime() . "\n";
    print OUTFILE "## created-by: " . getlogin . "\n";

    foreach my $project_name (sort keys %{$self->{_project_lookup}}){

        my $branch_list = $self->{_project_lookup}->{$project_name}->{'branch-list'};
        
        my $current_branch = $self->{_project_lookup}->{$project_name}->{'current_dev_branch'};
        
        my $next_branch = $self->{_project_lookup}->{$project_name}->{'next_dev_branch'};
        
        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        print OUTFILE "\n$project_name:\n\n";
        
        print OUTFILE "\tCurrent branch: '$current_branch'\n";
        
        print OUTFILE "\tRecommended next branch: '$next_branch'\n";
        
        print OUTFILE "\tRepository URL: '$repo_url'\n";
    }


    close OUTFILE;

    $self->{_logger}->info("Wrote report to '$report_file'");
}    

sub getCurrentBranchLookup {

    my $self = shift;

    if (! exists $self->{_current_branch_lookup}){

        foreach my $project_name (sort keys %{$self->{_project_lookup}}){

            my $current_dev_branch = $self->{_project_lookup}->{$project_name}->{'current_dev_branch'};

            $self->{_current_branch_lookup}->{$project_name} = $current_dev_branch;
        }   
    }

    return $self->{_current_branch_lookup};
}

sub getCurrentDevBranchByProject {

    my $self = shift;
    my ($project_name) = @_;

    if (!defined($project_name)){
        $self->{_logger}->logconfess("project_name was not defined");
    }

    if (! exists $self->{_current_branch_lookup}){
        $self->getCurrentBranchLookup();
    }

    if (!exists $self->{_current_branch_lookup}->{$project_name}){
        $self->{_logger}->logconfess("project name '$project_name' does not exist in the current branch lookup");
    }
    else {
        return $self->{_current_branch_lookup}->{$project_name};
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Branch::Manager
 A module for retrieving branch information from remote git repository.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Branch::Manager;
 my $manager = DevelopmentUtils::Git::Branch::Manager::getInstance();
 $manager->getNextDevelopmentBranches();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
