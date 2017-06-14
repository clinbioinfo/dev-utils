package DevelopmentUtils::Git::Project::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Basename;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Date::Util;

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

        $instance = new DevelopmentUtils::Git::Project::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Project::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initDateUtil(@_);

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

sub _initDateUtil {

    my $self = shift;

    my $util = DevelopmentUtils::Date::Util::getInstance(@_);
    if (!defined($util)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Date::Util");
    }

    $self->{_date_util} = $util;
}

sub archiveProject {


    my $self = shift;

    my $indir = $self->getIndir();
    if (!defined($indir)){
        $self->{_logger}->logconfess("indir was not defined");
    }

    $self->_check_indir_status($indir);


    my $answer;

    while (1) {

        print "Shall I archive project directory '$indir'? [Y/n/q] ";    
        
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

        my $date = $self->{_date_util}->getDateStamp();
        if (!defined($date)){
            $self->{_logger}->logconfess("date was not defined");
        }

        
        my $parent_dir = File::Basename::dirname($indir);

        my $basename = File::Basename::basename($indir);

        my $target = $basename . '.' . $date . '.tgz';

        chdir($parent_dir) || $self->{_logger}->logconfess("Could not change into directory '$parent_dir' : $!");

        my $cmd = "tar -zcf $target $basename --remove-files";
        
        $self->_execute_cmd($cmd);

        $self->{_logger}->info("Project directory '$indir' has been archived to '$target'");
    }
    else {

        print "Okay, I will not achive this project directory.\n";

        $self->{_logger}->info("User does not want to archive project directory '$indir'");
    }    
}

sub _check_indir_status {

    my $self = shift;
    my ($indir) = @_;

    if (!defined($indir)){
        $self->{_logger}->logconfess("indir was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $indir){
        
        $self->{_logger}->error("input directory '$indir' does not exist");
        
        $errorCtr++;
    }
    else {

        if (!-d $indir){
        
            $self->{_logger}->error("'$indir' is not a regular directory");
            
            $errorCtr++;
        }

        if (!-r $indir){
            
            $self->{_logger}->error("input directory '$indir' does not have read permissions");
            
            $errorCtr++;
        }        
    }
     
    if ($errorCtr > 0){
        
        $self->{_logger}->logconfess("Encountered issues with input directory '$indir'");
        
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


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Project::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Project::Manager;
 my $manager = DevelopmentUtils::Git::Project::Manager::getInstance();
 my $asset_list_content = $manager->getAssetListContent();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
