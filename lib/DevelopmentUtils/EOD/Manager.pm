package DevelopmentUtils::EOD::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

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

sub run {

    my $self = shift;
    $self->_prompt_about_reminder_email();
    $self->_check_sublime_snippets();
    $self->_recommend_new_aliases();
    $self->_check_git_status();
}

sub _prompt_about_reminder_email {

    my $self = shift;

    if ($self->_ask_whether_user_wants_to_send_reminder_email()){

        my $notes = $self->_get_reminder_notes();

        $self->_send_reminder($notes);
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
}

sub _check_sublime_snippets {

    my $self = shift;

    ## Detect new Sublime snippets and prompt me to commit those to dev-utils repository.

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}

sub _recommend_new_aliases {

    my $self = shift;

    ## Scan my history and recommend aliases to be added to .bashrc.    

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}

sub _check_git_status {

    my $self = shift;
    
    ## If in a project folder - perform a git status and prompt me it modified or untracked assets need to be staged and committed to revision control.

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
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
