
#!/usr/bin/env perl
use strict;
use Term::ANSIColor;
use FindBin;
use File::Copy;
use File::Path;
use File::Compare;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;
use DevelopmentUtils::Alias::Manager;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

my $username = $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . $username . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_BASHRC_FILE => '~/.bashrc';

use constant DEFAULT_SOURCE_ALIASES_FILE => "$FindBin::Bin/../doc/aliases.txt";

my $help;
my $man;
my $verbose;
my $test_mode;
my $outdir;
my $config_file;
my $log_file;
my $log_level;
my $bashrc_file;
my $source_aliases_file;
my $username;


my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'config_file=s' => \$config_file,
    'username=s'    => \$username,
    'bashrc-file=s'         => \$bashrc_file, 
    'source-aliases-file=s' => \$source_aliases_file
    );

&checkCommandLineArguments();

if (!-e $source_aliases_file){
	die "source aliases file '$source_aliases_file' does not exist";
}


if (!-e $bashrc_file){

	$bashrc_file = '/home/'. $username . '/.bashrc';

	if (!-e $bashrc_file){

		die "target .bashrc file '$bashrc_file' does not exist";
	}
}

&checkCommandLineArguments();

my $logger = DevelopmentUtils::Logger::getInstance(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

my $manager = DevelopmentUtils::Alias::Manager::getInstance(
    test_mode            => $test_mode,
    verbose              => $verbose,
    config_file          => $config_file,
    outdir               => $outdir,
    source_aliases_file  => $source_aliases_file,
    bashrc_file          => $bashrc_file,
    username             => $username
    );

if (!defined($manager)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Alias::Manager");
}

$manager->checkAliases();

if ($verbose){

    printGreen(File::Spec->rel2abs($0) . " execution completed");
}

print "The log file is '$log_file'\n";
exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;


    if ($fatalCtr > 0){
    	die "Required command-line arguments were not specified\n";
    }

    if (!defined($username)){

		$username =  getlogin || getpwuid($<) || "sundaramj";

        printYellow("--username was not specified and therefore was set to default '$username'");        
    }


    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;
        
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
        
    }


    if (!defined($bashrc_file)){

        $bashrc_file = DEFAULT_BASHRC_FILE;
        
        printYellow("--bashrc_file was not specified and therefore was set to default '$bashrc_file'");
        
    }


    if (!defined($source_aliases_file)){

        $source_aliases_file = DEFAULT_SOURCE_ALIASES_FILE;
        
        printYellow("--source_aliases_file was not specified and therefore was set to default '$source_aliases_file'");
        
    }

    if (!defined($config_file)){
        
        $config_file = DEFAULT_CONFIG_FILE;
        
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");        
    }


    if (!defined($log_level)){
        
        $log_level = DEFAULT_LOG_LEVEL;
        
        printYellow("--log_level was not specified and therefore was set to default '$log_level'");        
    }

 
    if (!defined($test_mode)){

        $test_mode = DEFAULT_TEST_MODE;
        
        printYellow("--test_mode was not specified and therefore was set to default '$test_mode'");        
    }

    if (!defined($outdir)){
        
        $outdir = DEFAULT_OUTDIR;
        
        printYellow("--outdir was not specified and therefore was set to default '$outdir'");        
    }

    if (!-e $outdir){
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        print "Created output directory '$outdir'\n";
    }

    if (!defined($log_file)){

        $log_file = $outdir . '/' . File::Basename::basename($0) . '.log';
        
        printYellow("--log_file was not specified and therefore was set to default '$log_file'");        
    }

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