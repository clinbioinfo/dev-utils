package DevelopmentUtils::Git::Clone::Manager;

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
use DevelopmentUtils::Git::Branch::Manager;
use DevelopmentUtils::Git::Tag::Manager;
use DevelopmentUtils::Git::Helper;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_PROJECTS_CONF_FILE => "$FindBin::Bin/../conf/projects_conf.json";


## Singleton support
my $instance;

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
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

has 'projects_conf_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProjectsConfFile',
    reader   => 'getProjectsConfFile',
    required => FALSE,
    default  => DEFAULT_PROJECTS_CONF_FILE
    );

has 'project' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProject',
    reader   => 'getProject',
    required => FALSE
    );


has 'branch' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setBranch',
    reader   => 'getBranch',
    required => FALSE
    );

has 'tag' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTag',
    reader   => 'getTag',
    required => FALSE
    );

has 'checkout_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCheckoutDirectory',
    reader   => 'getCheckoutDirectory',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Clone::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Clone::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initHelper(@_);

    $self->_initGitBranchManager(@_);

    $self->_initGitTagManager(@_);

    $self->_load_project_lookup(@_);

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

sub _initGitBranchManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Branch::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Branch::Manager");
    }

    $self->{_branch_manager} = $manager;
}

sub _initGitTagManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Tag::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Tag::Manager");
    }

    $self->{_tag_manager} = $manager;
}

sub _load_project_lookup {

    my $self = shift;

    my $lookup = $self->{_helper}->getProjectsLookup();

    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined");
    }

    $self->{_project_lookup} = $lookup;
}

sub cloneProject {

    my $self = shift;
    my ($project) = @_;

    if (!defined($project)){
        $project = $self->getProject();
        if (!defined($project)){
            $self->{_logger}->logconfess("project was not defined");
        }
    }
    else {
        $self->setProject($project);
    }


    $self->_clone_project($project);
}

sub checkoutBranch {

    my $self = shift;
    my ($project, $branch) = @_;

    if (!defined($project)){
        $project = $self->getProject();
        if (!defined($project)){
            $self->{_logger}->logconfess("project was not defined");
        }
    }
    else {
        $self->setProject($project);
    }

    if (!defined($branch)){
        $branch = $self->getBranch();
        if (!defined($branch)){
            $self->{_logger}->logconfess("branch was not defined");
        }
    }
    else {
        $self->setBranch($branch);
    }

    $self->_clone_project($project);

    $self->_checkout_branch($project, $branch);
}

sub _checkout_branch {

    my $self = shift;
    my ($project, $branch) = @_;

    my $cmd = "git checkout $branch";
    
    $self->_execute_cmd($cmd);

    print "Have checked out branch '$branch' into '$self->{_clone_dir}'\n";
}

sub checkoutTag {

    my $self = shift;
    my ($project, $branch, $tag) = @_;

    if (!defined($project)){
        $project = $self->getProject();
        if (!defined($project)){
            $self->{_logger}->logconfess("project was not defined");
        }
    }
    else {
        $self->setProject($project);
    }

    if (!defined($branch)){
        $branch = $self->getBranch();
        if (!defined($branch)){
            $self->{_logger}->logconfess("branch was not defined");
        }
    }
    else {
        $self->setBranch($branch);
    }

    if (!defined($tag)){
        $tag = $self->getTag();
        if (!defined($tag)){
            $self->{_logger}->logconfess("tag was not defined");
        }
    }
    else {
        $self->setTag($tag);
    }

    $self->_clone_project($project);

    $self->_checkout_tag($project, $branch, $tag);
}


sub _checkout_tag {

    my $self = shift;
    my ($project, $branch, $tag) = @_;

    my $cmd = "git checkout tags/$tag -b $branch";
    
    $self->_execute_cmd($cmd);

    print "Have checked out tag '$tag' (branch '$branch') into '$self->{_clone_dir}'\n";
    print "You can confirm with 'git describe --tags'\n";
}

sub _clone_project {

    my $self = shift;
    my ($project) = @_;

    my $repo_url = $self->_get_project_repo_url($project);

    my $outdir = $self->getOutdir();

    if (!defined($outdir)){
        mkpath($outdir) || $self->{_logger}->logconfess("Could not create output directory '$outdir' : $!");
        $self->{_logger}->info("Created output directory '$outdir'");
    }

    chdir($outdir) || $self->{_logger}->logconfess("Could not change into directory '$outdir' : $!");

    my $target_dir = $project;

    if (-e $target_dir){
        $target_dir = time() . '.' . $project;
    }

    my $cmd = "git clone $repo_url $target_dir";

    if ($self->getTestMode()){

        printYellow("Running in test mode - would have executed '$cmd' (rerun using --test_mode 0)");
    }
    else {

        $self->_execute_cmd($cmd);

        my $target_path = File::Spec->rel2abs($target_dir);

        $self->setCheckoutDirectory($target_path);

        print "The project has been clone to '$target_path'\n";

        chdir($target_path) || $self->{_logger}->logconfess("Could not change into directory '$target_path' : $!");

        $self->{_clone_dir} = $target_path;

        $self->_prompt_user_whether_wanted_to_checkout_branch_or_tag($project);

    }
}

sub _get_project_repo_url {

    my $self = shift;
    my ($project) = @_;

    if (!exists $self->{_project_lookup}->{$project}){
        $self->{_logger}->logconfess("project '$project' does not exist in the project lookup!");
    }
    else {
        if (!exists $self->{_project_lookup}->{$project}->{'repo-url'}){
            $self->{_logger}->logconfess("repository URL does not exist for project '$project' in the project lookup!");
        }
        else {
            return $self->{_project_lookup}->{$project}->{'repo-url'};
        }
    }
}

sub _prompt_user_whether_wanted_to_checkout_branch_or_tag {

    my $self = shift;
    my ($project) = @_;

    my $answer;

    while (1) {

        print "Do you want to checkout a branch or tag? [B/t/n/q] ";    
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ((!defined($answer)) || ($answer eq '')){
            $answer = 'B';
            last;
        }
        elsif (($answer eq 'B') || ($answer eq 'T') || ($answer eq 'N')){
            ## okay            
            last;
        }
        elsif ($answer eq 'Q'){

            print color 'bold red';
            print "Umm, okay- bye!\n";
            print color 'reset';

            exit(1);
        }
    }

    if ($answer eq 'B'){

        $self->{_logger}->info("User wants to checkout a branch");

        $self->_display_branch_list($project);

        my $branch = $self->_prompt_user_for_branch($project);

        $self->_checkout_branch($project, $branch);
    }
    elsif ($answer eq 'T'){

        $self->{_logger}->info("User wants to checkout a tag");

        $self->_display_tag_list($project);

        my $tag = $self->_prompt_user_for_tag($project);

        my $branch = $self->_derive_branch_from_tag($project, $tag);

        $self->_checkout_tag($project, $branch, $tag);
    }
    else {

        $self->{_logger}->info("User does not want to checkout a branch nor a tag");
    }
}

sub _derive_branch_from_tag {

    my $self = shift;
    my ($project, $tag) = @_;

    if ($tag =~ m|^v(\d+)\.(\d+)\.\d+$|){

        my $version = $1;

        my $revision = $2;

        my $derived_branch  = 'v' . $version .  '.' . $revision;

        $self->{_logger}->info("derived branch '$derived_branch' from tag '$tag' for project '$project'");

        return $derived_branch;
    }
    else {
        $self->{_logger}->logconfess("Unexpected tag '$tag' for project '$project' - could not derive the branch");
    }
}


sub _display_branch_list {

    my $self = shift;
    my ($project) = @_;

    print "Okay, retrieving branch list...\n";

    my $branch_list = $self->{_branch_manager}->getBranchListByProject($project);
    if (!defined($branch_list)){
        $self->{_logger}->logconfess("branch_list was not defined for project '$project'");
    }

    printYellow("Here are the available branches:");
    
    my $ctr = 0;
    
    my $FORMAT = "%-3s %-10s %-400s\n";

    foreach my $branch (@{$branch_list}){
    
        $ctr++;
    
        my $url = $self->_get_branch_url($branch);

        if (defined($url)){
           
           printf($FORMAT, $ctr .'.', $branch, "($url)");
        }
        else {

            $self->{_logger}->warn("url was not defined for branch '$branch'");

            printf($FORMAT, $ctr .'.', $branch, "(N/A)");
        }

        $self->{_branch_number_to_branch_name_lookup}->{$ctr} = $branch;
    }
}

sub _display_tag_list {

    my $self = shift;
    my ($project) = @_;

    print "Okay, retrieving tag list...\n";

    my $tag_list = $self->{_tag_manager}->getTagListByProject($project);
    if (!defined($tag_list)){
        $self->{_logger}->logconfess("tag_list was not defined for project '$project'");
    }

    printYellow("Here are the available tags:");

    my $ctr = 0;

    foreach my $tag (@{$tag_list}){

        $ctr++;

        print $ctr .". " . $tag . "\n";
    }
}

sub _prompt_user_for_branch {

    my $self = shift;
    my ($project) = @_;

    my $answer;

    while (1) {

        print "Please specify a branch (or pick a number): ";    
        
        $answer = <STDIN>;
        
        chomp $answer;        
        
        if ((!defined($answer)) || ($answer eq '')){
            next;
        }
        else {

            if (exists $self->{_branch_number_to_branch_name_lookup}->{$answer}){
                $answer = $self->{_branch_number_to_branch_name_lookup}->{$answer};                                
            }

            last;
        }
    }

    $self->{_logger}->info("User specified branch '$answer' for project '$project'");

    return $answer;
}

sub _prompt_user_for_tag {

    my $self = shift;
    my ($project) = @_;

    my $answer;

    while (1) {

        print "Please specify a tag: ";    
        
        $answer = <STDIN>;
        
        chomp $answer;        
        
        if ((!defined($answer)) || ($answer eq '')){
            next;
        }
        else {
            last;
        }

    }

    $self->{_logger}->info("User specified tag '$answer' for project '$project'");

    return $answer;
}

sub _get_branch_url {

    my $self = shift;
    my ($branch) = @_;

    my $base_url = $self->_get_browse_base_url();

    if (defined($base_url)){

        my $url = $base_url . 'browse?at=refs%2Fheads%2F' . $branch;

        $self->{_logger}->info("branch '$branch' has url '$url'");

        return $url;
    }
}

sub _get_browse_base_url {

    my $self = shift;

    if (!exists $self->{_git_projects_lookup}){

        my $file = $self->{_config_manager}->getGitProjectsLookupFile();
        if (!defined($file)){

            my $config_file = $self->{_config_manager}->getConfigfile();
            
            $self->{_logger}->logconfess("file was not defined [Git/projects_lookup_file] was not defined in the configuration file '$config_file'");
        }

        if (!-e $file){
            $self->{_logger}->logconfess("git project lookup file '$file' does not exist");
        }

        my $lookup = json_file_to_perl($file);
        if (!defined($lookup)){
            $self->{_logger}->logconfess("lookup was not defined for file '$file'");
        }

        $self->{_git_projects_lookup} = $lookup;
    }

    my $project = $self->getProject();

    if (exists $self->{_git_projects_lookup}->{$project}->{browse_url}){
        return $self->{_git_projects_lookup}->{$project}->{browse_url};
    }
    else {        

        my $file = $self->{_config_manager}->getGitProjectsLookupFile();
        if (!defined($file)){
            $self->{_logger}->logconfess("file was not defined");
        }

        printBoldRed("project '$project' does not have a record in '$file'");
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

 DevelopmentUtils::Git::Clone::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Clone::Manager;
 my $manager = DevelopmentUtils::Git::Clone::Manager::getInstance();
 $manager->cloneProject($project);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
