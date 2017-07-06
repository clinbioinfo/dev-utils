package DevelopmentUtils::Git::Manager;

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
use DevelopmentUtils::Atlassian::Jira::Manager;
use DevelopmentUtils::Git::Branch::Manager;
use DevelopmentUtils::Git::Tag::Manager;
use DevelopmentUtils::Git::Clone::Manager;
use DevelopmentUtils::Git::Stage::Manager;
use DevelopmentUtils::Git::Assets::Manager;


use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_JIRA_URL => '';

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

has 'jira_issue_id' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraIssueId',
    reader   => 'getJiraIssueId',
    required => FALSE
    );

has 'commit_comment_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitCommentFile',
    reader   => 'getCommitCommentFile',
    required => FALSE
    );

has 'commit_comment_content' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitCommentContent',
    reader   => 'getCommitCommentContent',
    required => FALSE
    );

has 'commit_asset_list_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitAssetListFile',
    reader   => 'getCommitAssetListFile',
    required => FALSE
    );

has 'jira_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraURL',
    reader   => 'getJiraURL',
    required => FALSE,
    default  => DEFAULT_JIRA_URL
    );

has 'include_jira_reference' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setIncludeJiraReference',
    reader   => 'getIncludeJiraReference',
    required => FALSE
    );

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

has 'commit_hash' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitHash',
    reader   => 'getCommitHash',
    required => FALSE
    );

has 'commit_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitURL',
    reader   => 'getCommitURL',
    required => FALSE
    );

has 'repo_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setRepoName',
    reader   => 'getRepoName',
    required => FALSE
    );


has 'project' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProject',
    reader   => 'getProject',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initGitBranchManager(@_);

    $self->_initGitTagManager(@_);

    $self->_initGitCloneManager(@_);

    $self->_initGitStageManager(@_);

    $self->_initGitAssetsManager(@_);

    $self->_conditional_init_jira_manager(@_);

    $self->{_confirmed_asset_file_ctr} = 0;

    $self->{_is_commit_pushed} = FALSE;

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}


sub _conditional_init_jira_manager {

    my $self = shift;
    
    my $jira_issue_id = $self->getJiraIssueId();

    my $jira_url = $self->getJiraURL();

    if (defined($jira_issue_id)){
        $self->_initJiraManager(@_);
        $self->{_jira_manager}->setIssueId($jira_issue_id);
    }

    if (defined($jira_url)){
        $self->_initJiraManager(@_);
        $self->{_jira_manager}->setIssueURL($jira_url);
    }        
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

sub _initJiraManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Atlassian::Jira::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Atlassian::Jira::Manager");
    }

    $self->{_jira_manager} = $manager;
}

sub _initGitBranchManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Branch::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Branch::Manager");
    }

    my $report_file = $self->getReportFile();

    if (defined($report_file)){

        my $current_report_file = $report_file;

        $report_file = $self->getOutdir() . '/' . File::Basename::basename($0) . '.branch-report.txt';

        $self->{_logger}->info("Overriding current report file '$current_report_file' with report file '$report_file");      

        $manager->setReportFile($report_file);
    }

    $self->{_branch_manager} = $manager;
}

sub _initGitTagManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Tag::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Tag::Manager");
    }

    my $report_file = $self->getReportFile();

    if (defined($report_file)){

        my $current_report_file = $report_file;

        $report_file = $self->getOutdir() . '/' . File::Basename::basename($0) . '.tag-report.txt';

        $self->{_logger}->info("Overriding current report file '$current_report_file' with report file '$report_file");      

        $manager->setReportFile($report_file);
    }
    
    $self->{_tag_manager} = $manager;
}

sub _initGitCloneManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Clone::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Clone::Manager");
    }

    my $report_file = $self->getReportFile();

    if (defined($report_file)){

        my $current_report_file = $report_file;

        $report_file = $self->getOutdir() . '/' . File::Basename::basename($0) . '.clone-report.txt';

        $self->{_logger}->info("Overriding current report file '$current_report_file' with report file '$report_file");      

        $manager->setReportFile($report_file);
    }

    $self->{_clone_manager} = $manager;
}

sub _initGitStageManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Git::Stage::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Stage::Manager");
    }

    $self->{_stage_manager} = $manager;
}

sub _initGitAssetsManager {

    my $self = shift;
    
    my $manager = DevelopmentUtils::Git::Assets::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Git::Assets::Manager");
    }

    $self->{_asset_manager} = $manager;
}

sub commitCodeAndPush {

    my $self = shift;

    $self->commitCode(@_);

    $self->_push_to_remote(@_);
}

sub _push_to_remote {

    my $self = shift;

    my $cmd  = 'git push';

    if ($self->getTestMode()){
        
        printYellow("Running in test mode - would have executed: $cmd");
        
        $self->{_logger}->info("Running in test mode - would have executed: $cmd");
        
        $self->{_is_commit_pushed} = FALSE;
    }
    else {

        $self->_execute_cmd($cmd);

        $self->{_is_commit_pushed} = TRUE;
    }
}

sub isCommitPushed {

    my $self = shift;

    return $self->{_is_commit_pushed};

}

sub commitCode {

    my $self = shift;

    $self->_prepare_commit_comment(@_);

    $self->_commit_code();

    $self->{_is_commit_pushed} = FALSE;
}

sub _commit_code {

    my $self = shift;

    my $comment_file = $self->getCommitCommentFile();

    if (!-e $comment_file){
        $self->{_logger}->logconfess("git commit comment file '$comment_file' does not exist");
    }
    
    my $asset_list_content  = $self->_get_asset_list_content();

    my $cmd = "git commit -F $comment_file " . $asset_list_content;

    if ($self->getTestMode()){

        printYellow("Running in test mode - would have executed: $cmd");

        $self->{_logger}->info("Running in test mode - would have executed: $cmd");
    }
    else {

        $self->_execute_cmd($cmd);

        my $commit_url = $self->_get_commit_url(); 

        if (defined($commit_url)){
        
            print "Here is the commit URL:\n";
        
            print $commit_url . "\n\n";
        
            # if (exists $self->{_jira_manager}){

            #     $self->{_jira_manager}->setCommitURL($commit_url);
            # }
        }
        # else {
        
        #     if (exists $self->{_jira_manager}){

        #         $self->{_logger}->warn("Could not set the commit URL commit '$commit_hash'");
        #     }
        # }
    }
}
sub _get_commit_url {

    my $self = shift;

    my $commit_hash = $self->_get_commit_hash();
    if (!defined($commit_hash)){
        $self->{_logger}->logconfess("commit_hash was not defined");
    }

    $self->setCommitHash($commit_hash);

    my $commits_base_url = $self->_get_commits_base_url();

    if (defined($commits_base_url)){
    
        if ($commits_base_url =~ m|/$|){
            $commits_base_url =~ s|/+$||;
        }
        
        my $commit_url = $commits_base_url . '/' . $commit_hash;

        $self->setCommitURL($commit_url);

        return $commit_url;
    }
}

sub _get_commit_hash {

    my $self = shift;

    my $cmd = "git rev-parse HEAD";

    my $results = $self->_execute_cmd($cmd);

    if ($results->[0] =~ m|^(\S+)\s*$|){
        return $1;
    }
}

sub _get_commits_base_url {

    my $self = shift;

    if (!exists $self->{_git_projects_lookup}){

        my $file = $self->{_config_manager}->getGitProjectsLookupFile();
        if (!defined($file)){
            $self->{_logger}->logconfess("file was not defined");
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

    my $repo_name = $self->_get_repo_name();

    if (exists $self->{_git_projects_lookup}->{$repo_name}->{commits_url}){
        return $self->{_git_projects_lookup}->{$repo_name}->{commits_url};
    }
    else {        

        my $file = $self->{_config_manager}->getGitProjectsLookupFile();
        if (!defined($file)){
            $self->{_logger}->logconfess("file was not defined");
        }

        printBoldRed("repository name '$repo_name' does not have a record in '$file'");
    }
}

sub _get_repo_name {

    my $self = shift;
    
    my $repo_name = $self->getRepoName();

    if (!defined($repo_name)){

        my $cmd = "git remote show origin";

        my $results = $self->_execute_cmd($cmd);

        if ($results->[1] =~ m|^\s+Fetch\s+URL:\s+(ssh:\S+)\s*$|){

            my $url = $1;

            my $basename = File::Basename::basename($url);

            $self->{_logger}->info("url '$url' basename '$basename'");

            if ($basename =~ m|\.git|){

                $basename =~ s|\.git||;
            }

            $repo_name = $basename;

            $self->setRepoName($repo_name);
        }
        else {
            $self->{_logger}->fatal("DEBUG:" . Dumper $results);
            $self->{_logger}->logconfess("Unexpected content '" . $results->[1] . "'");
        }
    }

    return $repo_name;
}

sub getFormattedCommitURL {

    my $self = shift;

    my $commit_url = $self->getCommitURL();

    if (defined($commit_url)){

        my $repo_name = $self->getRepoName();

        my $content = "Committed the following to [" . $repo_name . " | " . $commit_url . "].";

        $self->{_logger}->info("formatted commit URL '$content'");

        return $content;
    }
}

sub _prepare_commit_comment {

    my $self = shift;

    # my $jira_ticket = $self->_get_jira_ticket();

    my $file = $self->getCommitCommentFile();

    if (!defined($file)){

        my $content = $self->_prompt_user_about_commit_comment();

        $file = $self->getOutdir() . '/git-commit-comment.txt';

        $self->setCommitCommentFile($file);

        $self->_prompt_user_about_jira();

        $self->_write_comment_to_file($content, $file);
    }
    else {
        ## Eventhough the user already provided a commit comment file
        ## check to see whether user would like to add reference to some
        ## JIRA ticket.
        $self->_prompt_user_about_jira();
    }
}

sub _prompt_user_about_jira {

    my $self = shift;
  
    my $answer;

    while (1) {

        print "Do you want to include a reference to some JIRA issue? [Y/n/q] ";    
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ((!defined($answer)) || ($answer eq '')){
            $answer = 'Y';
            last;
        }
        elsif (($answer eq 'Y') || ($answer eq 'N')){
            ## okay            
            last;
        }
        elsif ($answer eq 'Q'){

            printBoldRed("Umm, okay- bye!");
            
            exit(1);
        }
    }

    if ($answer eq 'Y'){

        $self->{_logger}->info("User wants to include JIRA reference");

        $self->_initJiraManager();

        $self->{_jira_manager}->askUserForReference();

        $self->setIncludeJiraReference(TRUE);
    }
    else {

        $self->{_logger}->info("User does not want to include JIRA reference");

        $self->setIncludeJiraReference(FALSE);
    }
}

sub _prompt_user_about_commit_comment {

    my $self = shift;

    # my $jira_url = $self->_get_jira_url();

    print "Please type the git commit comment.\n";
    # print "The following reference will be appended to your comment:\n";
    # print "Reference: $jira_url\n";
    print "Press [ctrl-D] when done.\n\n";
        
    my @content = <STDIN>;

    my $joined_content = join("", @content);

    $self->setCommitCommentContent($joined_content);

    return $joined_content;
}

sub _write_comment_to_file {

    my $self = shift;
    my ($content, $outfile) = @_;

    my $outdir = File::Basename::dirname($outfile);

    if (!-e $outdir){
    
        mkpath($outdir) || $self->{_logger}->logconfess("Could not create outdir '$outdir' : $!");
    
        $self->{_logger}->info("Created outdir '$outdir'");
    }

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");
    
    print OUTFILE $content . "\n";

    if ($self->getIncludeJiraReference()){

        my $jira_url = $self->_get_jira_url();

        print OUTFILE "Reference: $jira_url\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote content to '$outfile'");    
}

sub _get_jira_url {

    my $self = shift;

    my $url = $self->{_jira_manager}->getIssueURL();
    if (!defined($url)){
        $self->{_logger}->logconfess("url was not defined");
    }

    return $url;
}

sub _get_asset_list_content {

    my $self = shift;

    return $self->{_stage_manager}->getAssetListContent(@_);
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

sub getCurrentBranches {

    my $self = shift;

    return $self->{_branch_manager}->getCurrentBranches(@_);
}
	
sub determineNextBranches {

    my $self = shift;
    
    return $self->{_branch_manager}->getDetermineNextBranches(@_);
}
    
sub createNextBuildTags {

    my $self = shift;       

    $self->{_branch_manager}->determineNextBranches(@_);

    my $current_branch_lookup = $self->{_branch_manager}->getCurrentBranchLookup();
    if (!defined($current_branch_lookup)){
        $self->{_logger}->logconfess("current_branch_lookup was not defined");
    }

    $self->{_tag_manager}->setCurrentBranchLookup($current_branch_lookup);

    $self->{_tag_manager}->createNextBuildTags(@_);
}

sub getBranchReportFile {

    my $self = shift;
    return $self->{_branch_manager}->getReportFile()
}

sub getTagReportFile {

    my $self = shift;
    return $self->{_tag_manager}->getReportFile()
}

sub cloneProject {

    my $self = shift;
    
    $self->{_clone_manager}->cloneProject(@_);
}

sub checkoutBranch {

    my $self = shift;
    
    $self->{_clone_manager}->checkoutBranch(@_);
}

sub checkoutTag {

    my $self = shift;
    
    $self->{_clone_manager}->checkoutTag(@_);
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

sub getCommitHashURL {

    my $self = shift;

    my $indir = $self->getIndir();
    
    chdir($indir) || $self->{_logger}->logconfess("Could not change into directory '$indir' : $!");

    return $self->_get_commit_url();
}

sub manageAssets {

    my $self = shift;

    my $project = $self->getProject();
    if (!defined($project)){
        $self->{_logger}->logconfess("project was not defined");
    }

    $self->{_clone_manager}->cloneProject($project);
    
    my $checkout_directory = $self->{_clone_manager}->getCheckoutDirectory();
    if (!defined($checkout_directory)){
        $self->{_logger}->logconfess("checkout_directory was not defined");
    }

    $self->{_asset_manager}->setCheckoutDirectory($checkout_directory);
    
    $self->{_asset_manager}->manageAssets();
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Manager;
 my $manager = DevelopmentUtils::Git::Manager::getInstance();
 $manager->commitCodeAndPush($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
