package DevelopmentUtils::Git::Tag::Manager;

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
use DevelopmentUtils::Git::Helper;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

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

        $instance = new DevelopmentUtils::Git::Tag::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Tag::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initHelper(@_);

    $self->_load_project_lookup(@_);

    $self->_set_report_file(@_);

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

    my $helper = DevelopmentUtils::Git::Helper::getInstance(@_);
    if (!defined($helper)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Helper");
    }

    $self->{_helper} = $helper;
}

sub _set_report_file {

    my $self = shift;

    my $report_file = $self->getReportFile();

    if (!defined($report_file)){

        $report_file = $self->getOutdir() . '/' . File::Basename::basename($0) . '.tag-report.txt';

        $self->{_logger}->info("report_file was not defined and therefore was set to '$report_file'");

        $self->setReportFile($report_file);
    }
}

# sub _initBranchManager {

#     my $self = shift;

#     my $outdir = $self->getOutdir();

#     my $report_file = $outdir . '/branch-report.rpt';

#     my $manager = DevelopmentUtils::Git::Branch::Manager::getInstance(
#         test_mode          => $self->getTestMode(),
#         verbose            => $self->getVerbose(),
#         config_file        => $self->getConfigFile(),
#         outdir             => $outdir,
#         projects_conf_file => $self->getProjectsConfFile(),
#         report_file        => $report_file
#     );

#     if (!defined($manager)){
#         $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Branch::Manager");
#     }

#     $self->{_branch_manager} = $manager;
# }

sub getCurrentTags {

    my $self = shift;
    my ($project)  = @_;

    if (defined($project)){

        $self->_get_all_build_tags($project);

        $self->_generate_current_tag_report($project);
    }
    else {
        
        foreach my $project (sort keys %{$self->{_project_lookup}}){
            $self->_get_all_build_tags($project);
        }

        $self->_generate_current_tag_report();
    }
}

sub _generate_current_tag_report {

    my $self = shift;
    my ($project) = @_;

    my $report_file = $self->getReportFile();

    open (OUTFILE, ">$report_file") || die "Could not open report file '$report_file' in write mode : $!";

    print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
    print OUTFILE "## date-created: " . localtime() . "\n";
    print OUTFILE "## created-by: " . getlogin . "\n";

    foreach my $project_name (sort keys %{$self->{_project_lookup}}){

        if ((defined($project)) && ($project ne $project_name)){
            next;
        }

        my $tag_list = $self->{_project_lookup}->{$project_name}->{'tag-list'};
                
        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        print OUTFILE "\n$project_name:\n\n";
        
        print OUTFILE "\tTag list:\n\n";
        
        foreach my $tag (@{$tag_list}){
            print OUTFILE "\t$tag\n";
        }
        
        print OUTFILE "\n\tRepository URL: '$repo_url'\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote report to '$report_file'");
}    


sub determineNextBuildTags {

    my $self = shift;

    return $self->recommendNextBuildTags(@_);
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

sub recommendNextBuildTags {

    my $self = shift;

    $self->_print_banner("Going to determine next build tags");

    foreach my $project_name (sort keys %{$self->{_project_lookup}}){
        
        if ($self->getVerbose()){

            print "Processing project '$project_name'\n";
        }

        my $current_build_tag = $self->_get_current_build_tag($project_name);
        
        my $next_build_tag = $self->_get_next_build_tag($project_name);

        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        if ($self->getVerbose()){

            print "For project '$project_name'\n";

            if (!defined($current_build_tag)){

                $current_build_tag = 'N/A';
                
                $self->{_logger}->info("current_build_tag was not defined and therefore will be reported as '$current_build_tag'");
            }

            print "Current build tag '$current_build_tag'\n";
            print "Recommended next build tag '$next_build_tag'\n";
            print "The repository URL is '$repo_url\n\n";
        }
    }

    $self->_generate_report();
}

sub _load_project_lookup {

    my $self = shift;

    my $lookup = $self->{_helper}->getProjectsLookup();

    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined");
    }

    $self->{_project_lookup} = $lookup;
}

sub _get_current_build_tag {

    my $self = shift;
    my ($project_name) = @_;

    $self->_get_all_build_tags($project_name);

    $self->_determine_current_and_next_build_tags($project_name);

    return $self->{_project_lookup}->{$project_name}->{current_build_tag};
}

sub _get_next_build_tag {

    my $self = shift;
    my ($project_name) = @_;

    return $self->{_project_lookup}->{$project_name}->{next_build_tag};
}

sub _get_all_build_tags {

    my $self = shift;
    my ($project_name) = @_;

    my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

    my $cmd = "git ls-remote -t $repo_url";

    my $branch_list = $self->_execute_cmd($cmd);

    my $candidate_list = [];
    my $candidate_ctr = 0 ;

    if (scalar(@{$branch_list}) > 0){

        foreach my $line (@{$branch_list}){

            if ($self->getVerbose()){
                print "tag: $line\n";
            }

            if ($line =~ m|^\S+\s+refs/tags/(\S+)\s*$|){

                my $candidate = $1;

                push(@{$candidate_list}, $candidate);

                $candidate_ctr++;
            }
        }
    }
    else {
        $self->{_logger}->warn("Did not find any tags for '$project_name' with repository URL '$repo_url'");
    }

    if ($candidate_ctr > 0){

        if ($self->getVerbose()){

            print "Found the following '$candidate_ctr' tags:\n";
            
            print join("\n", @{$candidate_list}) . "\n";
        }

        $self->{_project_lookup}->{$project_name}->{'tag-list'} = $candidate_list;

        $self->{_project_lookup}->{$project_name}->{'tag-count'} = $candidate_ctr;
    }
}

sub _determine_current_and_next_build_tags {

    my $self = shift;
    my ($project_name) = @_;

    if (! exists $self->{_project_lookup}->{$project_name}->{'tag-list'}){

        print color 'red';
        print "It appears there are no tags for project '$project_name'\n";
        print color 'reset';

        $self->_recommend_tag_based_on_latest_branch($project_name);

        return;
    }

    my $tag_list = $self->{_project_lookup}->{$project_name}->{'tag-list'};

    my $max_version = 0;
    my $max_revision = 0;
    my $max_build = 0;

    if (scalar @{$tag_list} > 0){

        foreach my $tag (@{$tag_list}){
            
            if ($tag =~ m|^v(\d+)\.(\d+)\.(\d+)\s*$|){
                
                my $version = $1;
                my $revision = $2;
                my $build = $3;
                
                if ($version > $max_version){
                    $max_version = $version;
                    $max_revision = 0;
                    $max_build = 0;
                }
                
                if ($revision > $max_revision){
                    $max_revision = $revision;
                    $max_build = 0;
                }
                
                if ($build > $max_build){
                    $max_build = $build;
                }
                
                next;
            }
            elsif ($tag =~ m|^v(\d+)\.(\d+)\.(\d+)\{\}\s*$|){
                $self->{_logger}->info("Ignoring tag '$tag'");
                next;
            }
            elsif ($tag =~ m|^v(\d+)\.(\d+)\.(\d+)\^\{\}\s*$|){
                $self->{_logger}->info("Ignoring tag '$tag'");
                next;
            }
            else {
                $self->{_logger}->logconfess("Unexpected tag '$tag' for project '$project_name'");
            }
        }
           
        my $current_build_tag = 'v' . $max_version . '.' . $max_revision . '.' . $max_build;

        $self->{_project_lookup}->{$project_name}->{current_build_tag} = $current_build_tag;   

        my $next_build_tag = 'v' . $max_version . '.' . $max_revision . '.' . ++$max_build; ## increment for the next build

        $self->{_project_lookup}->{$project_name}->{next_build_tag} = $next_build_tag;

       if ($self->getVerbose()){

            print color 'green';
            print "For project '$project_name' - the next development branch should be '$next_build_tag'\n";
            print color 'reset';
        }
    }
    else {
        print color 'bold red';
        print "There are no tags for project '$project_name'\n";
        print color 'reset';
    }
}

sub _recommend_tag_based_on_latest_branch {

    my $self = shift;
    my ($project_name) = @_;

    my $current_dev_branch = $self->_get_current_dev_branch($project_name);

    if ($current_dev_branch =~ m|v(\d+)\.(\d+)|){

        my $max_version = $1;
        my $max_revision = $2;

        my $next_build_tag = 'v' . $max_version . '.' . $max_revision . '.1';

        $self->{_project_lookup}->{$project_name}->{next_build_tag} = $next_build_tag;
    }
    else {

        if ($current_dev_branch eq 'master'){
            printYellow("Please create the development branch v1.1 for project '$project_name' and then manually create the next build tag v1.1.1");
        }
        else {
            $self->{_logger}->logconfess("Encountered some unexpected situation - project '$project_name' current dev branch '$current_dev_branch'");
        }
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

        my $tag_list = $self->{_project_lookup}->{$project_name}->{'tag-list'};
        
        my $current_branch = $self->{_project_lookup}->{$project_name}->{'current_build_tag'};
        
        my $next_branch = $self->{_project_lookup}->{$project_name}->{'next_build_tag'};
        
        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        print OUTFILE "\n$project_name:\n\n";
        
        print OUTFILE "\tCurrent branch: '$current_branch'\n";
        
        print OUTFILE "\tRecommended next branch: '$next_branch'\n";
        
        print OUTFILE "\tRepository URL: '$repo_url'\n";

        print OUTFILE "\tHere are the existing tags:\n";

        foreach my $tag (@{$tag_list}){
            print OUTFILE "\t\t$tag\n";
        }
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote report to '$report_file'");
}    

sub setCurrentBranchLookup {

    my $self = shift;
    my ($current_branch_lookup) = @_;

    if (!defined($current_branch_lookup)){
        $self->{_logger}->logconfess("current_branch_lookup was not defined");
    }

    $self->{_current_branch_lookup} = $current_branch_lookup;
}

sub _get_current_dev_branch {

    my $self = shift;
    my ($project_name) = @_;

    if (exists $self->{_current_branch_lookup}->{$project_name}){
        return $self->{_current_branch_lookup}->{$project_name};
    }

    $self->{_logger}->logconfess("project name '$project_name' does not exist in the current branch lookup");
}

sub createNextBuildTags {

    my $self = shift;

    # $self->{_branch_manager}->determineNextDevBranches();

    $self->recommendNextBuildTags();

    $self->_create_next_build_tags();
}

sub _create_next_build_tags {

    my $self = shift;
    
    $self->_print_banner("Going to created next build tags");

    my $workdir = $self->getOutdir();

    foreach my $project_name (sort keys %{$self->{_project_lookup}}){

        chdir($workdir) || $self->{_logger}->logconfess("Could not change into directory '$workdir' : $!");

        if ($self->getVerbose()){

            print "Processing project '$project_name'\n";

            print "Current working directory is '$workdir'\n";
        }

        my $repo_url = $self->{_project_lookup}->{$project_name}->{'repo-url'};

        $self->_clone_project($project_name, $repo_url);

        chdir($project_name) || $self->{_logger}->logconfess("Could not change into directory '$project_name' : $!");

        my $next_build_tag = $self->{_project_lookup}->{$project_name}->{next_build_tag};

        my $current_dev_branch = $self->_get_current_dev_branch($project_name);#{_branch_manager}->getCurrentDevBranchByProject($project_name);

        ## For situation where the current development branch has no tag-
        ## this software should recommend that the first tag for the
        ## branch should be created.
        $next_build_tag = $self->_verify_tag_against_branch($next_build_tag, $current_dev_branch);

        my $cmd_checkout_branch = "git checkout $current_dev_branch";

        $self->_execute_cmd($cmd_checkout_branch);

        my $date = localtime();

        my $cmd_create_tag = "git tag -a $next_build_tag -m 'Establishing $next_build_tag from dev branch $current_dev_branch on $date'";

        print "About to tag code base '$project_name' with tag '$next_build_tag' with the following command\n";

        print $cmd_create_tag . "\n";        
        
        print color 'yellow';
        print "Shall I proceed? [Y/n/o/q] ";
        print color 'reset';

        my $answer;
        
        while (1){
        
            $answer = <STDIN>;
        
            chomp $answer;

            if (!defined($answer)){
                $answer = 'Y';
            }
            if ($answer eq ''){
                $answer = 'Y';
            }

            $answer = uc($answer);

            if (($answer eq 'Y') || ($answer eq 'N') ||  ($answer eq 'O') || ($answer eq 'Q')){
                last;
            }
        }

        if ($answer eq 'Y'){

            $self->_do_create_tag_and_push($cmd_create_tag, $next_build_tag);
        }
        elsif ($answer eq 'N'){
            $self->{_logger}->info("User decided to not create tag '$next_build_tag' for code base '$project_name'");
            next;
        }
        elsif ($answer eq 'O'){

            $self->{_logger}->info("User decided to supply a different tag than '$next_build_tag' for code base '$project_name'");

            $next_build_tag = $self->_prompt_user_for_tag();

            $date = localtime();

            $cmd_create_tag = "git tag -a $next_build_tag -m 'Establishing $next_build_tag from dev branch $current_dev_branch on $date'";

            print "About to tag code base '$project_name' with tag '$next_build_tag' with the following command\n";

            $self->_do_create_tag_and_push($cmd_create_tag, $next_build_tag);

            next;
        }
        elsif ($answer eq 'Q'){
            $self->{_logger}->info("User decided to quit just before creating tag '$next_build_tag' for code base '$project_name'");
            exit;
        }
        else {
            $self->{_logger}->logconfess("Unexpected answer '$answer'");
        }
    }
}

sub _verify_tag_against_branch {

    my $self = shift;
    my ($next_build_tag, $current_dev_branch) = @_;

    my $current_dev_branch_revision_number;
    my $current_dev_branch_version_number;

    if ($current_dev_branch =~ m|^v(\d+)\.(\d+)$|){
        $current_dev_branch_version_number = $1;
        $current_dev_branch_revision_number = $2;
    }
    else {
        $self->{_logger}->logconfess("Unexpected branch '$current_dev_branch'");
    }
   
    my $next_build_tag_revision_number;
        
    if ($next_build_tag =~ m|^v\d+\.(\d+)\.\d+$|){
        $next_build_tag_revision_number = $1;
    }
    else {
        $self->{_logger}->logconfess("Unexpected build tag '$next_build_tag'");
    }
    

    if ($current_dev_branch_revision_number != $next_build_tag_revision_number){

        my $recommended_next_build_tag = 'v' . $current_dev_branch_version_number . '.' . $current_dev_branch_revision_number . '.1';

        $self->{_logger}->info("Recommending next build tag '$recommended_next_build_tag' instead of '$next_build_tag' because current development branch '$current_dev_branch'");

        return $recommended_next_build_tag;
    }
    else {
        return $next_build_tag;
    }
}


sub _prompt_user_for_tag {

    my $self = shift;
    
    my $answer;

    while(1){    
        
        print "Please provide the tag: ";
        
        $answer  = <STDIN>;
        
        chomp $answer;
        
        if ((!defined($answer)) || ($answer eq '')){
            next;
        }
        else {
            last;
        }
    }

    return $answer;
}

sub _do_create_tag_and_push {

    my $self = shift;
    my ($cmd_create_tag, $next_build_tag) = @_;

    if ($self->getTestMode()){

        $self->{_logger}->info("Running in test mode - would have executed '$cmd_create_tag' (re-execute with --test_mode 0)");

        print color 'yellow';
        print "Running in test mode - would have executed '$cmd_create_tag' (re-execute with --test_mode 0)\n";
        print color 'reset';
    }
    else {

        $self->_execute_cmd($cmd_create_tag);

        my $cmd_git_push = "git push origin $next_build_tag";

        $self->_execute_cmd($cmd_git_push);
    }
}

sub _clone_project {

    my $self = shift;
    
    my ($project_name, $repo_url) = @_;

    my $ex = "git clone $repo_url";

    $self->{_logger}->info("About to execute '$ex'");

    try {

        qx($ex);

    } catch {

        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$ex' : @_");
    };
}

sub getTagListByProject {

    my $self = shift;
    my ($project) = @_;
    if (!defined($project)){
        $self->{_logger}->logconfess("project was not defined");
    }

    if (! exists $self->{_project_to_tag_list_lookup}){
        
        $self->_get_all_build_tags($project);

        my $tag_list = $self->{_project_lookup}->{$project}->{'tag-list'};

        $self->{_project_to_tag_list_lookup}->{$project} = $tag_list;
    }

    return $self->{_project_to_tag_list_lookup}->{$project};
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

 DevelopmentUtils::Git::Tag::Manager
 A module for retrieving branch information from remote git repository.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Tag::Manager;
 my $manager = DevelopmentUtils::Git::Tag::Manager::getInstance();
 $manager->getNextDevelopmentBranches();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
