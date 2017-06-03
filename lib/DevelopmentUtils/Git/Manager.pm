package DevelopmentUtils::Git::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

my $login =  getlogin || getpwuid($<) || "";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_JIRA_URL => '';

## Singleton support
my $instance;

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

sub commitCodeAndPush {

    my $self = shift;

    $self->{_logger}->info("NOT YET IMPLEMENTED");

    $self->commitCode(@_);
}

sub commitCodeA {

    my $self = shift;

    $self->{_logger}->info("NOT YET IMPLEMENTED");

    $self->_prepare_commit_comment(@_);

    $self->_commit_code();
}

sub _commit_code {

    my $self = shift;

    $self->{_logger}->error("NOT YET IMPLEMENTED");
}


sub _prepare_commit_comment {

    my $self = shift;

    my $jira_ticket = $self->_get_jira_ticket();

    my $file = $self->getCommitCommentFile();

    if (!defined($file)){

        my $content = $self->_prompt_user_about_commit_comment();

        $file = $self->getOutdir() . '/git-commit-comment.txt';

        $self->_write_comment_to_file($content, $file);
    }
}

sub _prompt_user_about_commit_comment {

    my $self = shift;

    my $jira_url = $self->_get_jira_url();

    print "Please type the git commit comment.\n";
    print "The following reference will be appended to your comment:\n";
    print "Reference: $jira_url\n";
    print "Press [ctrl-D] when done.\n\n";
        
    my @content = <STDIN>;

    my $joined_content = join("\n", @content);

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

    my $jira_url = $self->_get_jira_url();

    print OUTFILE "Reference: $jira_url" . $self->getJiraTicket() . "\n";

    close OUTFILE;

    $self->{_logger}->info("Wrote content to '$outfile'");    
}

sub _get_jira_url {

    my $self = shift;

    my $jira_url = $self->getJiraURL();

    if (!defined($jira_url)){

        $self->{_config_manager}->getJiraURL();
    
        if (!defined($jira_url)){
        
            $jira_url = DEFAULT_JIRA_URL;
        
            $self->{_logger}->info("Jira URL was not defined and therefore was set to default '$jira_url'");
        }

        $self->setJiraURL($jira_url);
    }

    return $jira_url;
}


sub _get_jira_ticket {

    my $self = shift;

    my $jira_ticket = $self->getJiraTicket();

    if (!defined($jira_ticket)){
        $self->_prompt_about_jira_ticket();
    }

    if ($self->getIsAddJiraComment()){

        $jira_ticket = $self->getJiraTicket();

        $self->{_logger}->info("Will add a comment to the Jira ticket '$jira_ticket'");
    }
    else {
        $self->{_logger}->info("Will not add a comment to some Jira ticket");
    }


}

sub _prompt_about_jira_ticket {

    my $self = shift;

    my $jira_ticket;

    do {

        print "What is the Jira ticket identifier? ";

        $jira_ticket = <STDIN>;

        chomp $jira_ticket;     

        if ($self->_is_jira_ticket_valid($jira_ticket)){
            $jira_ticket = undef;
        }

    } while (!defined($jira_ticket));

    $self->setJiraTicket($jira_ticket);
}

sub _is_jira_ticket_valid {

    my $self = shift;
    my ($jira_ticket) = @_;

    $jira_ticket =~ s/^\s+//;

    $jira_ticket =~ s/\s+$//;

    if ($jira_ticket =~ /\S+\-\d+/){
        return TRUE;
    }

    return FALSE;
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
