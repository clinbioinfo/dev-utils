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
use DevelopmentUtils::Sublime::Snippets::Manager;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

my $username = $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . $username . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INSTALL_DIR => $ENV{HOME} . '/.config/sublime-text-3/Packages/User/';

use constant DEFAULT_SOURCE_DIR => "$FindBin::Bin/../sublime-snippets/snippets/";

my $install_dir;
my $source_dir;
my $log_level;
my $log_file;
my $outdir;
my $config_file;
my $verbose;

my $results = GetOptions (
    'install-dir=s'  => \$install_dir, 
    'source-dir=s'   => \$source_dir,
    'outdir=s'       => \$outdir,
    'log_file=s'     => \$log_file,
    'log_level=s'    => \$log_level,
    'config_file=s'  => \$config_file,
    'verbose=s'      => \$verbose
    );

&checkCommandLineArguments();


my $logger = DevelopmentUtils::Logger::getInstance(
	log_level => $log_level,
	log_file  => $log_file
	);

if (!defined($logger)){
	confess ("Could not instantiate DevelopmentUtils::Logger");
}

if (!-e $source_dir){
	$logger->logdie("source directory '$source_dir' does not exist");
}


if (!-e $install_dir){
	$logger->logdie("install directory '$install_dir' does not exist");
}


my $manager = DevelopmentUtils::Sublime::Snippets::Manager::getInstance(
	install_dir => $install_dir,
	repo_dir    => $source_dir,
	config_file => $config_file,
	verbose     => $verbose
	);

if (!defined($manager)){
	$logger->logconfess("Could not instantiate DevelopmentUtils::Sublime::Snippets::Manager");
}

$manager->installSublimeSnippets();

print "$0 execution completed\n";
print "The log file is '$log_file'\n";
exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;


    if (!defined($verbose)){

    	$verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");        
    }

    if (!defined($install_dir)){

    	$install_dir = DEFAULT_INSTALL_DIR;

        printYellow("--install-dir was not specified and therefore was set to default '$install_dir'");        
    }

    $install_dir = File::Spec->rel2abs($install_dir);

    if (!defined($source_dir)){
	
    	$source_dir = DEFAULT_SOURCE_DIR;

        printYellow("--source-dir was not specified and therefore was set to default '$source_dir'");
    }


    $source_dir = File::Spec->rel2abs($source_dir);

    if (!defined($config_file)){
        
        $config_file = DEFAULT_CONFIG_FILE;
        
        printYellow("--config_file was not specified and therefore was set to default '$config_file'");        
    }

    $config_file = File::Spec->rel2abs($config_file);

    if (!defined($log_level)){
        
        $log_level = DEFAULT_LOG_LEVEL;
        
        printYellow("--log_level was not specified and therefore was set to default '$log_level'");        
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

    if ($fatalCtr > 0){
    	die "Required command-line arguments were not specified\n";
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