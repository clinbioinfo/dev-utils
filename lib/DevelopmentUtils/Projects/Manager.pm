package DevelopmentUtils::Projects::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Basename;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'json_file_to_perl';

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Git::Status::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USE_QUALIFIED_PROJECT_DIRECTORIES_LOOKUP => FALSE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_PROJECTS_DIR => '/home/' . DEFAULT_USERNAME . '/projects';

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_REPORT_UNCOMMITTED_ASSETS_ONLY => FALSE;

## Singleton support
my $instance;

has 'report_uncommitted_assets_only' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setReportUncommittedAssetsOnly',
    reader   => 'getReportUncommittedAssetsOnly',
    required => FALSE,
    default  => DEFAULT_REPORT_UNCOMMITTED_ASSETS_ONLY
    );

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

has 'use_qualified_project_directories_lookup' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setUseQualifiedProjectDirectoriesLookup',
    reader   => 'getUseQualifiedProjectDirectoriesLookup',
    required => FALSE,
    default  => DEFAULT_USE_QUALIFIED_PROJECT_DIRECTORIES_LOOKUP
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

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

has 'projects_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProjecstDir',
    reader   => 'getProjectsDir',
    required => FALSE,
    default  => DEFAULT_PROJECTS_DIR
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

    $self->{_projects_dir} = $self->getProjectsDir();

    $self->{_current_dir} = File::Spec->rel2abs(cwd());

    $self->{_uncommitted_assets_ctr} = 0;

    $self->{_empty_directory_ctr} = 0;

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

sub _load_qualified_project_dir_lookup {

    my $self = shift;

    my $file = $self->{_config_manager}->getQualifiedProjectDirectoriesFile();
    if (!defined($file)){
        $self->{_logger}->logconfess("qualified project directories file was not defined");
    }

    $self->{_qualified_project_directories_file} = $file;

    my $lookup = json_file_to_perl($file);
    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined for file '$file'");
    }

    if (! exists $lookup->{qualified_project_directories}){
        $self->{_logger}->logconfess("qualified_project_directories does not exist in the lookup.  Please review file '$file'.");
    }

    $self->{_qualified_project_directories_lookup} = $lookup->{qualified_project_directories};

    $self->{_logger}->info("Loaded qualified project directories lookup from '$file'");
}

sub _is_directory_empty {

    my $self = shift;
    my ($dir) = @_;

    opendir(my $dh, $dir) or $self->{_logger}->logconfess("Could not open directory '$dir' : $!");
    
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}

sub run {

    my $self = shift;

    if (!-e $self->{_projects_dir}){
        $self->{_logger}->logconfess("projects directory '$self->{_projects_dir}' does not exist");
    }
    else {

        if ($self->getUseQualifiedProjectDirectoriesLookup()){
            $self->_load_qualified_project_dir_lookup();
        }
        else {
            $self->{_logger}->info("Will not use qualified project directories lookup");
        }

        $self->_analyze_projects_dir();

        $self->_display_findings();
    }
}

sub _analyze_projects_dir {

    my $self = shift;

    if ($self->getVerbose()){
        printBrightBlue("Will analyze projects directory '$self->{_projects_dir}'");
    }

   $self->{_logger}->info("Will analyze projects directory '$self->{_projects_dir}'");

    my $cmd = "find $self->{_projects_dir} -maxdepth 1 -type d";

    my $results = $self->_execute_cmd($cmd);

    foreach my $project_dir (@{$results}){

        if ($project_dir eq $self->{_projects_dir}){
            next;
        }

        if (!-e $project_dir){
            $self->{_logger}->logconfess("project directory '$project_dir' does not exist");
        }

        if (!-d $project_dir){
            $self->{_logger}->logconfess("'$project_dir' is not a regular directory");
        }

        if ($self->_is_directory_empty($project_dir)){

            push(@{$self->{_empty_directory_list}}, $project_dir);

            $self->{_empty_directory_ctr}++;

            $self->{_logger}->info("Looks like project directory is empty.  Skipping.");

            next;
        }

        if (File::Basename::basename($project_dir) eq 'archive'){

            $self->{_logger}->info("Skipping directory '$project_dir'");
            
            next;
        }

        if ($self->getUseQualifiedProjectDirectoriesLookup()){

            if (! exists $self->{_qualified_project_directories_lookup}->{$project_dir}){

                $self->{_logger}->info("project directory '$project_dir' is not a qualified project directory so will be skipped");

                next;
            }
        }

        push(@{$self->{_project_dir_list}}, $project_dir);

        $self->{_project_dir_ctr}++;

        # print Dumper $self->{_project_dir_list};
        # print "project_dir '$project_dir'\n";
        # print "project dir $self->{_project_dir}\n";
        # die "testing";
        $self->_analyze_project_dir($project_dir);
    }

    if ($self->{_project_dir_ctr} > 0){
        
        if ($self->getVerbose()){

            if ($self->getUseQualifiedProjectDirectoriesLookup()){

                print "Found the following '$self->{_project_dir_ctr}' qualified project directories:\n";
            }
            else {
                print "Found the following '$self->{_project_dir_ctr}' project directories:\n";   
            }
            
            print join("\n", @{$self->{_project_dir_list}}) . "\n";
        }
    }
    else {
        
        printBoldRed("Did not find any project directories in '$self->{_projects_dir}'");
        
        if ($self->getUseQualifiedProjectDirectoriesLookup()){
        
            print "Please review contents of the qualified project directories file '$self->{_qualified_project_directories_file}' and ensure your project directories are listed there.\n";
        }

        exit(1);
    }
}

sub _analyze_project_dir {

    my $self = shift;
    my ($project_dir) = @_;

    if ($self->getVerbose()){
        printBrightBlue("Will analyze project directory '$project_dir'");
    }

    $self->{_logger}->info("Will analyze project directory '$project_dir'");

    my $cmd = "find $project_dir -maxdepth 1 -type d";

    my $results = $self->_execute_cmd($cmd);

    foreach my $project_version_dir (@{$results}){

        if ($project_version_dir eq $project_dir){
            next;
        }

        # my $subdir = $self->{_project_dir} . '/' . $project_dir;

        if (!-e $project_version_dir){
            $self->{_logger}->logconfess("project version directory '$project_version_dir' does not exist");
        }

        if (!-d $project_version_dir){
            $self->{_logger}->logconfess("'$project_version_dir' is not a regular directory");
        }

        if ($self->_is_directory_empty($project_version_dir)){

            push(@{$self->{_empty_directory_list}}, $project_version_dir);

            $self->{_empty_directory_ctr}++;

            $self->{_logger}->info("Looks like project version directory is empty.  Skipping.");

            next;
        }

        my $git_file = $project_version_dir . '/.git';
        
        if (!-e $git_file){
            $self->{_logger}->info("$project_version_dir is not a git project.  Skipping");
            next;
        }

        $self->_analyze_project_version_dir($project_version_dir);
    }
}

sub _analyze_project_version_dir {

    my $self = shift;
    my ($project_version_dir) = @_;

    ## 1. Determine if is a git local checkout
    ## 2. Determine if there are any uncommitted assets
    ## 3. Prompt user if wants to archive OR remove OR view list of uncommitted assets OR just continue

    if ($self->getVerbose()){
        printBrightBlue("\nWill analyze project version directory '$project_version_dir");
    }

    chdir($project_version_dir) || $self->{_logger}->logconfess("Could not change to directory '$project_version_dir' : $!");

    my $manager = new DevelopmentUtils::Git::Status::Manager(
        outdir => $self->getOutdir,
        indir  => $project_version_dir,
        verbose => FALSE
        );

    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Status::Manager");
    }

    $self->{_current_status_manager} = $manager;

    $self->{_current_project_version_dir} = $project_version_dir;

    if ($manager->checkForUncommittedAssets()){

        push(@{$self->{_project_version_dir_to_uncommitted_assets_list}}, $project_version_dir);
        
        $self->{_uncommitted_assets_ctr}++;
        
        if (!$self->getReportUncommittedAssetsOnly()){
        
            printBoldRed("Found uncommitted assets");
        }
    }

    if (!$self->getReportUncommittedAssetsOnly()){

        $self->_prompt_user_regarding_project_version_dir();
    }
}

sub _prompt_user_regarding_project_version_dir {

    my $self = shift;
    
    my $answer;

    while (1){

        print "\nHow would you like to proceed?\n";
        print "1. View list of uncommitted assets\n";
        print "2. Archive the project directory\n";
        print "3. Remove the project directory\n";
        print "4. Skip and continue to next project directory\n";
        print "5. Quit\n";

        print "Select option (pick an option 1 through 5): ";

        $answer = <STDIN>;

        chomp $answer;

        if (($answer =~ m|^\d{1}$|) && ($answer == int($answer))){

            if ($answer == 1){
                $self->_display_list_uncommitted_assets();
                next;
            }
            elsif ($answer == 2){
                $self->_archive_project_version_directory();                
                last;
            }
            elsif ($answer == 3){
                $self->_remove_project_version_directory();
                last;
            }
            elsif ($answer == 4){
                last;
            }
            elsif ($answer == 5){

                printBoldRed("Umm... okay- bye.");
                exit(0);
            }

            last;
        }
    }
}

sub _display_list_uncommitted_assets {

    my $self = shift;

    my $list = $self->{_current_status_manager}->getUncommittedAssetsList();
    if (!defined($list)){
        $self->{_logger}->logconfess("list was not defined");
    }

    printYellow("\nHere are the uncommitted assets:");
    print join("\n", @{$list}) . "\n";
}

sub _archive_project_version_directory {

    my $self = shift;
    printYellow("Would have archived project version directory\n");
}

sub _remove_project_version_directory {

    my $self = shift;
    printYellow("Would have removed project version directory\n");
}

sub _display_findings {

    my $self = shift;
    
    print "Completed analysis of projects directory '$self->{_projects_dir}'\n";
    # print "Found the following '$self->{_project_dir_count}' project directories under '$self->{_projects_dir}'\n";

    if ($self->{_uncommitted_assets_ctr} > 0){
        
        printBoldRed("The following '$self->{_uncommitted_assets_ctr}' project version directories have committed assets");
        
        print join("\n", @{$self->{_project_version_dir_to_uncommitted_assets_list}}) . "\n";
    }


    if ($self->{_empty_directory_ctr} > 0){

        printBoldRed("The following '$self->{_empty_directory_ctr}' directories are empty");
        
        print join("\n", @{$self->{_empty_directory_list}}) . "\n";

        print "Shall I remove them? [y/N] ";
        
        my $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ($answer eq 'Y'){
            $self->_remove_empty_directories();
        }        
    }
}

sub _remove_empty_directories {

    my $self = shift;

    foreach my $dir (@{$self->{_empty_directory_list}}){

        my $cmd = "rmdir $dir";

        if ($self->getTestMode()){
            printYellow("Running in test mode - would have executed: '$cmd'");
        }
        else {
            $self->_execute_cmd($cmd);
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

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print  $msg . "\n";
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
