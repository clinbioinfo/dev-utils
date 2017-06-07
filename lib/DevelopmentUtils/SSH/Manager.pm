package DevelopmentUtils::SSH::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Compare;
use File::Copy;
use FindBin;
# use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'json_file_to_perl';

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => FALSE;

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

has 'ssh_conf_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSSHConfFile',
    reader   => 'getSSHConfFile',
    required => FALSE
    );

has 'username' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setUsername',
    reader   => 'getUsername',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::SSH::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::SSH::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_load_ssh_lookup(@_);

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

sub _load_ssh_lookup {

    my $self = shift;
    my $file = $self->getSSHConfFile;
    if (!defined($file)){
        $self->{_logger}->logconfess("SSH configuration JSON file '$file' was not defined");
    }

    if (!-e $file){
        $self->{_logger}->logconfess("SSH configuration JSON file '$file' does not exist");
    }

    my $lookup = json_file_to_perl($file);
    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined for file '$file'");
    }

    $self->{_ssh_lookup} = $lookup;

    $self->{_logger}->info("Loaded SSH lookup from file '$file'");    
}

sub run {

    my $self = shift;

    $self->_prompt_user();
}


sub _prompt_user {

    my $self = shift;
    
    my $answer;

    while(1){

        print "Here are your options:\n";
        print "1. List all known servers\n";
        print "2. Set-up password-less SSH\n";
        print "3. Something else\n";
        print "What would you like to do? [1|2|3|Q]";

        $answer = <STDIN>;

        chomp $answer;

        if ($answer eq '1'){
            $self->_list_all_known_servers();
            last;
        }
        elsif ($answer eq '2'){
            $self->_setup_passwordless_ssh();
            last;
        }
        elsif ($answer eq '3'){
            print "Alrighty then.  Have fun!\n";
            last;
        }
        elsif (($answer eq 'Q') || ($answer eq 'q')){
            print "Okay, see you later.\n";
            last;
        }
    }
}

sub _list_all_known_servers {

    my $self = shift;
    
    my $ctr = 0;

    my $lookup = {};

    foreach my $alias (sort keys %{$self->{_ssh_lookup}}){

        $ctr++;

        my $ip = $self->{_ssh_lookup}->{$alias}->{ip};
        
        my $desc = $self->{_ssh_lookup}->{$alias}->{desc};

        $lookup->{$ctr} = $alias;

        print $ctr . ". '$desc' is at $alias ('$ip')\n"; 
    }

    print "Please select: ";

    my $answer = <STDIN>;

    chomp $answer;

    if (exists $lookup->{$answer}){

        my $username = $self->getUsername();

        my $server = $lookup->{$answer};

        print "ssh -X $username\@$server\n";
    }
    else {
        print "That is not an option.  Bye.\n";
    }
}

sub _setup_passwordless_ssh {

    my $self = shift;

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
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

 DevelopmentUtils::SSH::Manager
 A module for managing SSH activities.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::SSH::Manager;
 my $manager = DevelopmentUtils::SSH::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
