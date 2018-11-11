package DevelopmentUtils::Atlassian::Jira::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Slurp;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use JIRA::Client::Automated;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_USERNAME => 'sundaramj';

my $login =  getlogin || getpwuid($<) || "sundaramj";

# use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();
use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_JIRA_REST_URL => 'http://informatics/tracker/rest/api/2/search';

use constant DEFAULT_JIRA_ISSUE_REST_URL => 'http://informatics/tracker/rest/api/2/issue';

## Singleton support
my $instance;

has 'username' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setUsername',
    reader   => 'getUsername',
    required => FALSE,
    default  => DEFAULT_USERNAME
    );

has 'password' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setPassword',
    reader   => 'getPassword',
    required => FALSE
    );

has 'jira_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraURL',
    reader   => 'getJiraURL',
    required => FALSE,
    );

has 'issue_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIssueURL',
    reader   => 'getIssueURL',
    required => FALSE
    );

has 'jira_rest_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraRESTURL',
    reader   => 'getJiraRESTURL',
    required => FALSE,
    default  => DEFAULT_JIRA_REST_URL
    );

has 'jira_issue_rest_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraIssueRESTURL',
    reader   => 'getJiraIssueRESTURL',
    required => FALSE,
    default  => DEFAULT_JIRA_ISSUE_REST_URL
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

has 'issue_id' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIssueId',
    reader   => 'getIssueId',
    required => FALSE
    );

has 'comment_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommentFile',
    reader   => 'getCommentFile',
    required => FALSE
    );

has 'comment' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setComment',
    reader   => 'getComment',
    required => FALSE
    );

has 'credential_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_credential_file',
    reader   => 'get_credential_file',
    required => FALSE
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Atlassian::Jira::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Atlassian::Jira::Manager";
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

sub addCommentN {

    my $self = shift;
    my (%args) = @_;

    return $self->addComment($args{issue_id}, $args{comment});
}


sub addComment {

    my $self = shift;
    my ($issue_id, $comment) = @_;

    if (!defined($issue_id)){

        $issue_id = $self->getIssueId();

        if (!defined($issue_id)){

            $self->{_logger}->info("issue_id was not defined");

            $self->askUserForReference();

            $issue_id = $self->getIssueId();

            if (!defined($issue_id)){
                $self->{_logger}->logconfess("issue_id was not defined");
            }
        }
    }

    if (!defined($comment)){

        $comment = $self->getComment();

        if (!defined($comment)){

            $comment = $self->_prompt_user_for_comment();
        }
    }

    my $username = $self->_getUsername();
    
    my $password = $self->_getPassword();

    my $data = $self->_getData($comment);
    
    my $url = $self->_get_rest_api_issue_end_point($issue_id);
    if (!defined($url)){
        $self->{_logger}->logconfess("url was not defined for issue_id '$issue_id'");
    }

    my $cmd = "curl -D- -u $username:$password -X POST --data '$data' -H 'Content-Type: application/json' $url";

    print "Going to execute '$cmd'\n";

    my $results = $self->_execute_cmd($cmd);

    if (! $self->isOkay($results)){
        $self->{_logger}->logconfess("The POST to Jira was not successful");
    }
}

sub isOkay {

    my $self = shift;
    my ($results) = @_;

    my $error_ctr = 0;

    foreach my $line (@{$results}){

        if ($line =~ /errorMessage/){
            $error_ctr++;
        }
    }

    if ($error_ctr > 0){
        return FALSE;
    }

    return TRUE;
}


sub _prompt_user_for_comment {

    my $self = shift;
 
    print "Please provide your Jira comment.\n";
    print "The following reference will be appended to your comment:\n";
    print "Reference: [some-url]\n";
    print "Press [ctrl-D] when done.\n\n";
        
    my @content = <STDIN>;

    my $joined_content;

    foreach my $line (@content){
        chomp $line;
        $joined_content .= $line . '\\n';
    }

    return $joined_content;
}

sub _getData {

    my $self = shift;
    my ($comment) = @_;

    my $data = '{"body":"' . $comment . '"}';

    return $data;
}

sub _getUsername {

    my $self = shift;
    my $username = $self->getUsername();

    if (!defined($username)){

        $username = $self->{_config_manager}->getJiraUsername();

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->info("username was not defined so was set to '$username' from the configuration file '$config_file'");        

        if (!defined($username)){

            $username = DEFAULT_USERNAME;

            $self->{_logger}->warn("username was not defined so was set to default '$username'");
        }

        $self->setUsername($username);
    }

    return $username;
}

sub _getPassword {

    my $self = shift;

    my $password = $self->getPassword();

    if (!defined($password)){

        $password = $self->{_config_manager}->getJiraPassword();

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->info("password was not defined so was set to '$password' from the configuration file '$config_file'");        

        if (!defined($password)){

            $password = $self->_prompt_for_jira_password();
        }

        $self->setPassword($password);
    }

    return $password;
}

sub _prompt_for_jira_password {

    my $self = shift;

    $self->{_logger}->fatal("DEBUG: NOT YET IMPLEMENTED");
}

sub _get_rest_api_issue_end_point {

    my $self = shift;
    my ($issue_id) = @_;

    my $jira_rest_url = $self->_get_jira_rest_url();

    if ($jira_rest_url =~ m|/$|){
        $jira_rest_url =~ s|/+$||;  ## remove all trailing forward slashes
    }

    my $final_url = $jira_rest_url . '/' . $issue_id . '/comment';

    return $final_url;
}

sub _get_jira_rest_url {

    my $self = shift;
    
    my $jira_rest_url = $self->{_config_manager}->getJiraIssueRESTURL();

    if ((!defined($jira_rest_url)) || ($jira_rest_url eq '')){

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->logconfess("JIRA issue REST URL could not be retrieved from configuration file '$config_file'");
    }

    return $jira_rest_url;
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

    foreach my $line (@results){
        $self->{_logger}->info("$line");
    }

    return \@results;
}

sub askUserForReference {

    my $self = shift;

    my $answer;

    do {

        print "What is the JIRA issue identifier or URL? ";    
        
        $answer = <STDIN>;
        
        chomp $answer;      

    } while ((!defined($answer)) && ($answer ne ''));

    if ($answer =~ m|http://|){

        ## E.g.: http://informatics/tracker/browse/BDMTNG-549

        $self->setIssueURL($answer);
        
        $self->_derive_and_set_issue_identifier();

        $self->{_logger}->info("user specified JIRA issue URL '$answer'");
    }
    else {
        
        ## E.g.: BDMTNG-549

        $self->setIssueId($answer);
        
        $self->_derive_and_set_issue_url();

        $self->{_logger}->info("user specified JIRA issue identifier '$answer'");
    }
}

sub _derive_and_set_issue_identifier {

    my $self = shift;
    my $url = $self->getIssueURL();
    if (!defined($url)){
        $self->{_logger}->logconfess("url was not defined");
    }

    my $issue_id = File::Basename::basename($url);

    $self->setIssueId($issue_id);
}

sub _derive_and_set_issue_url {

    my $self = shift;
    my $id = $self->getIssueId();
    if (!defined($id)){
        $self->{_logger}->logconfess("id was not defined");
    }

    my $base_url = $self->{_config_manager}->getJIRABaseURL();
    if (!defined($base_url)){
        $self->{_logger}->logconfess("base_url was not defined");
    }

    my $url = $base_url . $id;

    $self->setIssueURL($url);
}



sub _get_jira_issue_id {

    my $self = shift;

    my $id = $self->getIssueId();

    if (!defined($id)){
        $self->_prompt_about_jira_issue_id();
    }

    if ($self->getIsAddJiraComment()){

        $id = $self->getIssueId();

        $self->{_logger}->info("Will add a comment to the Jira issue with identifier '$id'");
    }
    else {
        $self->{_logger}->info("Will not add a comment to some Jira issue");
    }
}

sub _prompt_about_jira_issue_id {

    my $self = shift;

    my $id;

    do {

        print "What is the Jira issue identifier? ";

        $id = <STDIN>;

        chomp $id;     

        if ($self->_is_jira_issue_id_valid($id)){
            $id = undef;
        }

    } while (!defined($id));

    $self->setIssueId($id);
}

sub _is_jira_issue_id_valid {

    my $self = shift;
    my ($id) = @_;

    $id =~ s/^\s+//;

    $id =~ s/\s+$//;

    if ($id =~ /\S+\-\d+/){
        return TRUE;
    }

    return FALSE;
}

sub get_issue {

    my $self = shift;
    my ($id) = @_;

    if (!defined($id)){
        $self->{_logger}->logconfess("id was not defined");
    }

    $self->_init_automation();

    return $self->{_converter}->get_issue($self->{_automation_util}->get_issue($id));
}

sub _get_util {

    my $self = shift;
    
    if (! exists $self->{_automation_util}){
        
        my $util = new JIRA::Client::Automated($self->getJiraURL, $self->getUsername, $self->getPassword);
        if (!defined($util)){
            $self->{_logger}->logconfess("Could not instantiate JIRA::Client::Automated");
        }

        $self->{_automation_util} = $util;


        my $converter = DevelopmentUtils::Atlassian::Jira::Converter::getInstance();
        if (!defined($converter)){
            $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Atlassian::Jira::Converter");
        }

        $self->{_converter} = $converter;
    }
}

sub _initialize_credentials {

    my $self = shift;

    my $file = $self->get_credential_file;
    if (!defined($file)){
        $self->{_logger}->logconfess("file was not defined");
    }
    
    my @content = read_file($file);
    
    chomp @content;
    
    my $cred_line = $content[0];
    
    my ($username, $password) = split(/:/, $cred_line);

    $self->setUsername($username);
    $self->setPassword($password);
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Atlassian::Jira::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Atlassian::Jira::Manager;
 my $manager = DevelopmentUtils::Atlassian::Jira::Manager::getInstance();
 $manager->addCodeCommitComment($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
