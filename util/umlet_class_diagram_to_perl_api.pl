#!/usr/bin/env perl

use strict;
use Carp;
use File::Path;
use File::Basename;
use File::Spec;
use Term::ANSIColor;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use FindBin;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_USERNAME => $ENV{USER};

use constant DEFAULT_LOG_LEVEL => 3;

use constant DEFAULT_SUPPRESS_CHECKPOINTS => FALSE;

use constant DEFAULT_OUTDIR_BASE => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/';

use constant DEFAULT_POD_SOFTWARE_VERSION => '1.0';

use constant DEFAULT_POD_AUTHOR => 'Jaideep Sundaram';

use constant DEFAULT_POD_AUTHOR_EMAIL_ADDRESS => 'sundaramj.medimmune@gmail.com';

use constant DEFAULT_SKIP_GREEN_MODULES => TRUE;


$|=1; ## do not buffer output stream

## Parse command line options
my ($infile, 
    $outdir, 
    $log_level, 
    $help, 
    $logfile, 
    $man,
    $verbose, 
    $suppressCheckpoints,
    $softwareVersion, 
    $softwareAuthor, 
    $authorEmailAddress, 
    $skipGreenModules);

my $results = GetOptions (
      'log_level|d=s'           => \$log_level, 
      'help|h'                  => \$help,
      'man|m'                   => \$man,
      'infile=s'                => \$infile,
      'outdir=s'                => \$outdir,
      'logfile=s'               => \$logfile,
      'verbose=s'               => \$verbose,
      'software_version=s'      => \$softwareVersion,
      'software_author=s'       => \$softwareAuthor,
      'author_email_address=s'  => \$authorEmailAddress,
      'suppress-checkpoints=s'  => \$suppressCheckpoints,
      'skip_green_modules'      => \$skipGreenModules,
);

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    logfile   => $logfile, 
    log_level => $log_level
);

if (!defined($logger)){
    die "Could not instantiate DevelopmentUtils::Logger";
}

my $converter = DevelopmentUtils::UmletClassDiagramToPerlModule::Converter::getInstance(
    infile               => $infile,
    outdir               => $outdir,
    verbose              => $verbose,
    suppress_checkpoints => $suppressCheckpoints,
    skip_green_modules   => $skipGreenModules,
    software_version     => $softwareVersion,
    software_author      => $softwareAuthor,    
    author_email_address => $authorEmailAddress
    );

if (!defined($converter)){
    $logger->logdie("Could not instantiate DevelopmentUtils::UmletClassDiagramToPerlModule::Converter");
}
    
$converter->run();

printGreen(File::Spec->rel2abs($0) . " execution completed");

print "The log file is '$logfile'\n";

exit(0);

##-----------------------------------------------------------
##
##    END OF MAIN -- SUBROUTINES FOLLOW
##
##-----------------------------------------------------------

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
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

sub checkCommandLineArguments {
   
    if ($man){

    	&pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }
    
    if ($help){

    	&pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    my $fatalCtr=0;

    if (!defined($infile)){
        
    	printBoldRed("--infile was not specified");
        
    	$fatalCtr++;
    }
    else {

        $infile = File::Spec->rel2abs($infile);

        &checkInfileStatus($infile);
    }


    if ($fatalCtr> 0 ){
    	die "Required command-line arguments were not specified\n";
    }

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
        
    }

    if (!defined($skipGreenModules)){

        $skipGreenModules = DEFAULT_SKIP_GREEN_MODULES;

        printYellow("--skip_green_modules was not specified and therefore was set to default '$skipGreenModules'");        
    }

    if (!defined($suppressCheckpoints)){

        $suppressCheckpoints = DEFAULT_SUPPRESS_CHECKPOINTS;

        printYellow("--suppress_checkpoints was not specified and therefore was set to default '$suppressCheckpoints'");
    }

    if (!defined($softwareVersion)){

        $softwareVersion = DEFAULT_POD_SOFTWARE_VERSION;
        
        printYellow("--software_version was not specified and therefore was set to default '$softwareVersion'");
    }

    if (!defined($softwareAuthor)){

        $softwareAuthor = DEFAULT_POD_AUTHOR;

        printYellow("--software_author was not specified and therefore was set to '$softwareAuthor'");
    }

    if (!defined($authorEmailAddress)){

        $authorEmailAddress = DEFAULT_POD_AUTHOR_EMAIL_ADDRESS;
        
        printYellow("--author_email_address was not specified and therefore was set to '$authorEmailAddress'");        
    }

    if (!defined($log_level)){

        $log_level = DEFAULT_LOG_LEVEL;
        
        printYellow("--log_level was not specified and therefore was set to '$log_level'");        
    }

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR_BASE . &getInputFileBasename($infile) . '/' . time();

        printYellow("--outdir was not specified and therefore was set to '$outdir'");
    }

    if (!-e $outdir){

        mkpath ($outdir) || die "Could not create output directory '$outdir' : $!";
        
        printYellow("Created output directory '$outdir'");        
    }

    &checkOutdirStatus($outdir);

    if (!defined($logfile)){
    	
        $logfile = $outdir . '/' . File::Basename::basename($0) . '.log';
        
    	printYellow("--logfile was not specified and therefore was set to '$logfile'");        
    }
}

sub getInputFileBasename {

    my ($infile) = @_;

    my $basename = File::Basename::basename($infile);

    my @parts = split(/\./, $basename);

    pop(@parts); ## get rid of the filename extension

    return join('', @parts);
}


sub checkInfileStatus {

    my ($infile) = @_;
    
    if (!defined($infile)){
        die("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){
    
        printBoldRed("input file '$infile' does not exist");
        
        $errorCtr++;
    }
    else {

        if (!-f $infile){
        
            printBoldRed("'$infile' is not a regular file");
        
            $errorCtr++;
        }

        if (!-r $infile){
            
            printBoldRed("input file '$infile' does not have read permissions");
            
            $errorCtr++;
        }

        if (!-s $infile){

            printBoldRed("input file '$infile' does not have any content");

            $errorCtr++;
        }
    }

    if ($errorCtr > 0){
        
        printBoldRed("Encountered issues with input file '$infile'");
        
        exit(1);
    }
}

sub checkOutdirStatus {

    my ($outdir) = @_;

    if (!-e $outdir){
        
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        
        printYellow("Created output directory '$outdir'");        
    }
    
    if (!-d $outdir){
        
        printBoldRed("'$outdir' is not a regular directory");
        
    }
}