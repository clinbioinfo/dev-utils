package DevelopmentUtils::EOD::Manager;

use Moose;
use Cwd;
use Try::Tiny;
use Data::Dumper;
use File::Path;
use FindBin;
# use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Mailer;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Sublime::Snippets::Manager;
use DevelopmentUtils::Alias::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_SUBLIME_INSTALL_DIR => '~/.config/sublime-text-3/Packages/User/';

use constant DEFAULT_SUBLIME_REPOSITORY_DIR => "$FindBin::Bin/../sublime-snippets/snippets/";

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_BASHRC_FILE=> '~/.bashrc';

use constant DEFAULT_BASHRC_CONFIG_FILE=> "$FindBin::Bin/../doc/aliases.txt";

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

has 'sublime_install_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSublimeInstallDir',
    reader   => 'getSublimeInstallDir',
    required => FALSE,
    default  => DEFAULT_SUBLIME_INSTALL_DIR
    );

has 'sublime_repo_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSublimeRepoDir',
    reader   => 'getSublimeRepoDir',
    required => FALSE,
    default  => DEFAULT_SUBLIME_REPOSITORY_DIR
    );

has 'bashrc_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setBashrcFile',
    reader   => 'getBashrcFile',
    required => FALSE,
    default  => DEFAULT_BASHRC_FILE
    );

has 'bashrc_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setBashrcConfigFile',
    reader   => 'getBashrcConfigFile',
    required => FALSE,
    default  => DEFAULT_BASHRC_CONFIG_FILE
    );



sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::EOD::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::EOD::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initMailer(@_);

    $self->_initSublimeSnippetsManager(@_);

    $self->_initAliasManager(@_);

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

sub _initMailer {

    my $self = shift;

    my $mailer = DevelopmentUtils::Mailer::getInstance(@_);
    if (!defined($mailer)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Mailer");
    }

    $self->{_mailer} = $mailer;
}

sub _initSublimeSnippetsManager {

    my $self = shift;

    my $install_dir = $self->getSublimeInstallDir();

    my $repo_dir = $self->getSublimeRepoDir();

    my $outdir = $self->getOutdir();

    my $config_file = $self->getConfigFile();

    my $manager = DevelopmentUtils::Sublime::Snippets::Manager::getInstance(
        install_dir => $install_dir,
        repo_dir    => $repo_dir,
        outdir      => $outdir,
        config_file => $config_file
        );

    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Sublime::Snippets::Manager");
    }

    $self->{_sublime_snippets_manager} = $manager;
}

sub _initAliasManager {

    my $self = shift;

    my $bashrc_file = $self->getBashrcFile();

    my $bashrc_config_file = $self->getBashrcConfigFile();

    my $outdir = $self->getOutdir();

    my $config_file = $self->getConfigFile();

    my $manager = DevelopmentUtils::Alias::Manager::getInstance(
        bashrc_file        => $bashrc_file,
        bashrc_config_file => $bashrc_config_file,
        outdir             => $outdir,
        config_file        => $config_file
        );

    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Alias::Manager");
    }

    $self->{_alias_manager} = $manager;
}


sub run {

    my $self = shift;

    $self->_prompt_about_reminder_email();
    
    $self->_check_sublime_snippets();
    
    $self->_recommend_new_aliases();
    
    $self->_check_git_status();
    
    $self->_check_status_of_services();
}

sub _prompt_about_reminder_email {

    my $self = shift;

    if ($self->_ask_whether_user_wants_to_send_reminder_email()){

        my $notes = $self->_get_reminder_notes();

        $self->{_reminder_notes} = $notes;

        # $self->_send_reminder($notes);
    }
}

sub _get_reminder_notes {

    my $self = shift;

    print "Please type up your notes.\n";
    print "Press [ctrl-D] when done.\n\n";
        
    my @content = <STDIN>;

    my $joined_content = join("", @content);

    return $joined_content;    
}

sub _send_reminder {

    my $self = shift;
    my ($notes) = @_;

    $self->{_mailer}->setEmail(message => $notes);

    $self->{_mailer}->sendNotification();
}

sub _check_sublime_snippets {

    my $self = shift;

    ## Detect new Sublime snippets and prompt me to commit those to dev-utils repository.
    $self->_print_banner("Will check Sublime snippets");

    try {
        $self->{_sublime_snippets_manager}->checkSnippets();
    } catch {

        $self->{_logger}->error("Caught some exception while attempting to check Sublime snippets : $_");

        printBoldRed("Caught some exception while attempting to check Sublime snippets : $_");
    }
}

sub _recommend_new_aliases {

    my $self = shift;

    ## Scan my history and recommend aliases to be added to .bashrc.    
    $self->_print_banner("Will recommend aliases");

    try {

        $self->{_alias_manager}->recommendAliases();

    } catch {

        $self->{_logger}->error("Caught some exception while attempting to recommend aliases : $_");

        printBoldRed("Caught some exception while attempting to recommend aliases : $_");
    };
}

sub _check_git_status {

    my $self = shift;
    
    ## If in a project folder - perform a git status and prompt me it modified or untracked assets need to be staged and committed to revision control.
    $self->_print_banner("Will check (git) status of current project directory");

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}
 
sub _check_status_of_services {

    my $self = shift;
    
    ## Will check for heartbeat for following services:
    ## 1. important servers
    ## 2. important databases
    ## 3. applications deployed by this team
    ## 4. important productivity services/tools like Atlassian Stash Git 
    ## 5. team Atlassian JIRA
    $self->_print_banner("Will status of services");

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}
 
sub _ask_whether_user_wants_to_send_reminder_email {

    my $self = shift;
  
    my $answer;

    while (1) {

        print "Do you want to send yourself an email reminder? [Y/n/q] ";    
        
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

        $self->{_logger}->info("User wants to send an email reminder");

        $self->{_send_email_reminder} = TRUE;
    }
    else {

        $self->{_logger}->info("User does not want to send an email reminder");

        $self->{_send_email_reminder} = FALSE;
    }
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

 DevelopmentUtils::EOD::Manager
 A module for executing set of tasks at end-of-business-day. 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::EOD::Manager;
 my $manager = DevelopmentUtils::EOD::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
