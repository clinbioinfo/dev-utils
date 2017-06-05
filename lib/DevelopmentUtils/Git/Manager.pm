package DevelopmentUtils::Git::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Atlassian::Jira::Manager;
use DevelopmentUtils::Git::Branch::Manager;
use DevelopmentUtils::Git::Tag::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

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

has 'jira_ticket' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraTicket',
    reader   => 'getJiraTicket',
    required => FALSE
    );

has 'commit_comment_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitCommentFile',
    reader   => 'getCommitCommentFile',
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

    $self->_conditional_init_jira_manager(@_);

    $self->{_confirmed_asset_file_ctr} = 0;

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}


sub _conditional_init_jira_manager {

    my $self = shift;
    
    my $jira_ticket = $self->getJiraTicket();

    my $jira_url = $self->getJiraURL();

    if (defined($jira_ticket)){
        $self->_initJiraManager(@_);
        $self->{_jira_manager}->setIssueId($jira_ticket);
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

        $report_file = $self->getOutdir() . '/git-branch-report.txt';

        $self->{_logger}->info("Overriding current report file '$current_report_file' with report file '$report_file");      
    }

    $manager->setReportFile($report_file);

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

        $report_file = $self->getOutdir() . '/git-tag-report.txt';

        $self->{_logger}->info("Overriding current report file '$current_report_file' with report file '$report_file");      
    }

    $manager->setReportFile($report_file);

    $self->{_tag_manager} = $manager;
}

sub commitCodeAndPush {

    my $self = shift;

    $self->{_logger}->info("NOT YET IMPLEMENTED");

    $self->commitCode(@_);

    $self->_push_to_remote(@_);
}

sub _push_to_remote {

    my $self = shift;

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");

    my $cmd  = 'git push';

    if ($self->getTestMode()){
        print color 'yellow';
        print "Running in test mode - would have executed: '$cmd'\n";
        print color 'reset';
        $self->{_logger}->info("Running in test mode - would have executed '$cmd'");
    }
}

sub commitCode {

    my $self = shift;

    $self->{_logger}->info("NOT YET IMPLEMENTED");

    $self->_prepare_commit_comment(@_);

    $self->_commit_code();
}

sub _commit_code {

    my $self = shift;

    $self->{_logger}->error("NOT YET IMPLEMENTED");

    my $comment_file = $self->getCommitCommentFile();

    if (!-e $comment_file){
        $self->{_logger}->logconfess("git commit comment file '$comment_file' does not exist");
    }
    
    my $asset_list_content  = $self->_get_asset_list_content();

    if ($self->getTestMode()){

        print color 'yellow';
        print "Running in test mode - would have execute: git commit -F $comment_file " . $asset_list_content . "\n";
        print color 'reset';

        $self->{_logger}->info("Running in test mode - would have execute: git commit -F $comment_file " . $asset_list_content);
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

            print color 'bold red';
            print "Umm, okay- bye!\n";
            print color 'reset';

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

    my $asset_file = $self->getCommitAssetListFile();

    if (!defined($asset_file)){
    
        $self->{_logger}->info("asset_file was not defined");
    
        $asset_file = $self->getOutdir() . '/asset-list-file.txt';

        $self->setCommitAssetListFile($asset_file);

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    if (!-e $asset_file){

        $self->{_logger}->info("asset list file '$asset_file' does not exist");

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    $self->_parse_asset_list_file($asset_file);

    if ($self->{_confirmed_asset_file_ctr} > 0){
        return join(' ', @{$self->{_confirmed_asset_file_list}});
    }
}

sub _parse_asset_list_file {

    my $self = shift;
    my ($asset_file) = @_;

    my @content = read_file($asset_file);

    my $asset_content_list;

    my $found_changes_not_staged_section = FALSE;
    my $found_untracked_files_section = FALSE;
    my $found_the_end = FALSE;

    my $changes_not_staged_ctr = 0;
    my $untracked_files_ctr = 0;

    $self->{_modified_file_list} = [];
    $self->{_modified_file_ctr} = 0;

    $self->{_untracked_file_list} = [];
    $self->{_untracked_file_ctr} = 0;

    foreach my $line (@content){

        chomp $line;

        if ($line =~ /^\s*$/){
            next;
        }

        if ($line =~ /^\s*\(/){
            $self->{_logger}->info("Ignoring this line '$line'");
            next;
        }

        if ($line =~ m|^Changes not staged for commit:|){

            print "Found unstaged modified files section\n";
        
            $found_changes_not_staged_section = TRUE;
        
            next;
        }

        if ($line =~ m|^Untracked files:|){
        
            print "Found untracked files section\n";

            $found_untracked_files_section = TRUE;
            
            $found_changes_not_staged_section = FALSE;

            next;
        }

        if ($line =~ m|no changes added to commit|){

            print "Found end section\n";

            $found_the_end = TRUE;

            $found_untracked_files_section = FALSE;
            
            $found_changes_not_staged_section = FALSE;

        } 

        if ($found_changes_not_staged_section){

            if ($line =~ m|^\s+modified:\s+(\S+)\s*$|){

                my $modified_file = $1;

                if (!-e $modified_file){
                    $self->{_logger}->logconfess("modified file '$modified_file' does not exist");
                }

                push(@{$self->{_modified_file_list}}, $modified_file);

                $self->{_modified_file_ctr}++;                
            }
            elsif ($line =~ m|^\s+deleted:\s+(\S+)\s*$|){

                my $deleted_file = $1;

                $self->{_logger}->info("Going to ignored deleted file '$deleted_file'");
            }
            else {
                $self->{_logger}->logconfess("Unexpected line '$line'");
            }

            next;
        }

        if ($found_untracked_files_section){

            if ($line =~ m|^\s+(\S+)\s*$|){

                my $untracked_file = $1;

                if (!-e $untracked_file){
                    $self->{_logger}->logconfess("untracked file '$untracked_file' does not exist");
                }

                push(@{$self->{_untracked_file_list}}, $untracked_file);

                $self->{_untracked_file_ctr}++;
            }
            else {
                $self->{_logger}->logconfess("Unexpected line '$line'");
            }
        }
    }

    if ($self->{_modified_file_ctr} > 0){
        
        print "\nFound the following '$self->{_modified_file_ctr}' modified files:\n";
        
        print join("\n", @{$self->{_modified_file_list}}) . "\n";

        $self->_ask_user_about_modified_files();
    }
    else {
        $self->{_logger}->info("Did not find any modified files");
    }

    if ($self->{_untracked_file_ctr} > 0){

        print "\nFound the following '$self->{_untracked_file_ctr}' untracked files:\n";
        
        print join("\n", @{$self->{_untracked_file_list}}) . "\n";

        $self->_ask_user_about_untracked_files();
    }
    else {
        $self->{_logger}->info("Did not find any untracked files");
    }

    if (($self->{_modified_file_ctr} == 0)  && ($self->{_untracked_file_ctr} == 0)){
        $self->{_logger}->logconfess("Did not find any modified files nor any untracked files");
    }

    $self->_stage_files();
}


sub _stage_files {

    my $self = shift;

    if (($self->{_stage_modified_file_ctr} == 0) && ($self->{_stage_untracked_file_ctr} == 0)){
        print color 'bold red';
        print "User does not have any files to be staged.\n";
        print color 'reset';
        exit(2);
    }

    if ($self->{_stage_modified_file_ctr} > 0){
        $self->_stage_modified_files();
    }
    else {
        print color 'yellow';
        print "User does not want to stage any of the '$self->{_modified_file_ctr}' modified files\n";
        print color 'reset';
        $self->{_logger}->warn("User does not want to stage any of the '$self->{_modified_file_ctr}' modified files");
    }

    if ($self->{_stage_untracked_file_ctr} > 0){
        $self->_stage_untracked_files();
    }
    else {
        print color 'yellow';
        print "User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files\n";
        print color 'reset';
        
        $self->{_logger}->warn("User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files");
    }
}


sub _ask_user_about_modified_files {

    my $self = shift;

    print "\nLooks like there are '$self->{_modified_file_ctr}' modified files to be staged to be committed to git.\n";
    print "Please confirm which ones you'd like to stage.\n";

    $self->{_stage_modified_file_list} = [];
    $self->{_stage_modified_file_ctr} = 0;

    my $file_ctr = 0;

    foreach my $modified_file (sort @{$self->{_modified_file_list}}){
    
        $file_ctr++;

        while (1) {

            print $file_ctr . ". " . $modified_file . " [Y/n/q]";
            
            my $answer = <STDIN>;
            
            chomp $answer;
            
            $answer = uc($answer);

            if ($answer eq ''){
                $answer = 'Y';
            }
            
            if ($answer eq 'Y'){

                push(@{$self->{_stage_modified_file_list}}, $modified_file);

                $self->{_stage_modified_file_ctr}++;

                goto NEXT_MODIFIED_FILE;
            }
            elsif ($answer eq 'N'){
                
                $self->{_logger}->info("user did not want to stage modified file '$modified_file'");

                goto NEXT_MODIFIED_FILE;
            }
            elsif ($answer eq 'Q'){

                print color 'red';
                print "Umm, okay- bye\n";
                print color 'reset';
                
                $self->{_logger}->info("user asked to quit");
                
                exit(1);
            }
        }

        NEXT_MODIFIED_FILE: 
    }
}

sub _stage_modified_files {

    my $self = shift;

    foreach my $file (@{$self->{_stage_modified_file_list}}){
    
        push(@{$self->{_confirmed_asset_file_list}}, $file);
    
        $self->{_confirmed_asset_file_ctr}++;
    }

    my $cmd = "git add " . join(' ', @{$self->{_stage_modified_file_list}});
    
    if ($self->getTestMode()){
        print color 'yellow';
        print "Running in test mode - would have executed '$cmd'\n";
        print color 'reset';
        $self->{_logger}->info("Running in test mode - would have executed '$cmd'");
    }
}

sub _ask_user_about_untracked_files {

    my $self = shift;

    print "\nLooks like there are '$self->{_untracked_file_ctr}' untracked files to be staged to be committed to git.\n";
    print "Please confirm which ones you'd like to stage.\n";

    $self->{_stage_untracked_file_list} = [];
    $self->{_stage_untracked_file_ctr} = 0;

    my $file_ctr = 0;

    foreach my $untracked_file (sort @{$self->{_untracked_file_list}}){
    
        $file_ctr++;

        while (1) {

            print $file_ctr . ". " . $untracked_file . " [Y/n/q]";
            
            my $answer = <STDIN>;
            
            chomp $answer;
            
            $answer = uc($answer);
            
            if ($answer eq ''){
                $answer = 'Y';
            }

            if ($answer eq 'Y'){

                push(@{$self->{_stage_untracked_file_list}}, $untracked_file);

                $self->{_stage_untracked_file_ctr}++;

                goto NEXT_UNTRACKED_FILE;
            }
            elsif ($answer eq 'N'){
                
                $self->{_logger}->info("user did not want to stage untracked file '$untracked_file'");

                goto NEXT_UNTRACKED_FILE;
            }
            elsif ($answer eq 'Q'){
            
                print color 'red';
                print "Umm, okay- bye\n";
                print color 'reset';

                $self->{_logger}->info("user asked to quit");
                
                exit(1);
            }
        }

        NEXT_UNTRACKED_FILE: 
    }
}

sub _stage_untracked_files {

    my $self = shift;

    foreach my $file (@{$self->{_stage_untracked_file_list}}){
    
        push(@{$self->{_confirmed_asset_file_list}}, $file);
    
        $self->{_confirmed_asset_file_ctr}++;
    }

    my $cmd = "git add " . join(' ', @{$self->{_stage_untracked_file_list}});

    if ($self->getTestMode()){
        print color 'yellow';
        print "Running in test mode - would have executed '$cmd'\n";
        print color 'reset';
        $self->{_logger}->info("Running in test mode - would have executed '$cmd'");
    }
}

sub _derive_asset_list_file_via_status {

    my $self = shift;
    my ($asset_file) = @_;

    my $cmd = "git status";

    my $results = $self->_execute_cmd($cmd);

    open (OUTFILE, ">$asset_file") || $self->{_logger}->logconfess("Could not open '$asset_file' in write mode : $!");
    
    foreach my $line (@{$results}){
        print OUTFILE $line . "\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote to '$asset_file'");
}


#     my $jira_url = $self->getJiraURL();

#     if (!defined($jira_url)){

#         $self->{_config_manager}->getJiraURL();
    
#         if (!defined($jira_url)){
        
#             $jira_url = DEFAULT_JIRA_URL;
        
#             $self->{_logger}->info("Jira URL was not defined and therefore was set to default '$jira_url'");
#         }

#         $self->setJiraURL($jira_url);
#     }

#     return $jira_url;
# }



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
