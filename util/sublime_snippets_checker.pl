#!/usr/bin/env perl
use strict;
use Term::ANSIColor;
use FindBin;
use File::Path;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use FindBin;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;
use DevelopmentUtils::Sublime::Snippets::Manager;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_LOG_LEVEL => 4;

my $username = $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . $username . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INSTALL_DIR => '~/.config/sublime-text-3/Packages/User/';

use constant DEFAULT_REPOSITORY_DIR => "$FindBin::Bin/../sublime-snippets/snippets/";

my $install_dir;
my $repo_dir;
my $log_file;
my $log_level;
my $outdir;
my $config_file;

my $results = GetOptions (
    'install-dir=s'  => \$install_dir, 
    'repo-dir=s'     => \$repo_dir,
    'outdir=s'       => \$outdir,
    'log_file=s'     => \$log_file,
    'log_level=s'    => \$log_level,
    'config_file=s'  => \$config_file
    );

&checkCommandLineArguments();


my $logger = DevelopmentUtils::Logger::getInstance(
	log_level => $log_level,
	log_file  => $log_file
	);

if (!defined($logger)){
	confess ("Could not instantiate DevelopmentUtils::Logger");
}


if (!-e $install_dir){

	$logger->warn("Perl seems to believe that the install directory '$install_dir' does not exist, but will press on and see what happens.");

    printYellow("Perl seems to believe that the install directory '$install_dir' does not exist, but will press on and see what happens.");
}

if (!-e $repo_dir){
	$logger->logdie("repository directory '$repo_dir' does not exist");
}

my $manager = DevelopmentUtils::Sublime::Snippets::Manager::getInstance(
	install_dir => $install_dir,
	repo_dir    => $repo_dir,
	config_file => $config_file
	);

if (!defined($manager)){
	$logger->logconfess("Could not instantiate DevelopmentUtils::Sublime::Snippets::Manager");
}

$manager->checkSnippets();


print "$0 execution completed\n";
exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;


    if (!defined($log_level)){
        
        $log_level = DEFAULT_LOG_LEVEL;
        
        printYellow("--log_level was not specified and therefore was set to default '$log_level'");        
    }

    if (!defined($config_file)){
        
        $config_file = DEFAULT_CONFIG_FILE;
        
        printYellow("--config_file was not specified and therefore was set to default '$config_file'");        
    }


    if (!defined($install_dir)){

    	$install_dir = DEFAULT_INSTALL_DIR;

        printYellow("--install-dir was not specified and therefore was set to default '$install_dir'");        
    }

    if (!defined($repo_dir)){
	
    	$repo_dir = DEFAULT_REPOSITORY_DIR;

        printYellow("--repo-dir was not specified and therefore was set to default '$repo_dir'");
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