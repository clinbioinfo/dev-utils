#!/usr/bin/env perl

use strict;
use Cwd;
use File::Basename;
use File::Path;
use File::Spec;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Term::ANSIColor;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/checksum_assets.ini";

my (
    $config_file,
    $help,
    $indir,
    $log_file,
    $log_level,
    $man,
    $outdir,
    $outfile,
    $test_mode,
    $verbose,
    );

my $results = GetOptions (
    'config_file=s' => \$config_file,
    'help|h'        => \$help,
    'indir|h'        => \$indir,
    'log_file=s'    => \$log_file,
    'log_level=s'   => \$log_level,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'outfile=s'      => \$outfile,
    'test_mode=s'   => \$test_mode,
    'verbose=s'     => \$verbose,
    );

&checkCommandLineArguments();

my $logger = DevelopmentUtils::Logger::getInstance(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    confess ("Could not instantiate DevelopmentUtils::Logger");
}


main();

if ($verbose){
    print color 'green';
    print File::Spec->rel2abs($0) . " execution completed\n";
    print color 'reset';
}

print "The log file is '$log_file'\n";

exit(0);

##----------------------------------------------------------------------
##
##   END OF MAIN -- SUBROUTINES FOLLOW
##
##----------------------------------------------------------------------

sub checkCommandLineArguments {

    if ($man){
    	&pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
    	&pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");

    }

    if (!defined($config_file)){

        $config_file = DEFAULT_CONFIG_FILE;

        printYellow("--config_file was not specified and therefore was set to default '$config_file'");
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

    if (!defined($outfile)){

        $outfile = $outdir . '/' . File::Basename::basename($0) . '.txt';

        printYellow("--outfile was not specified and therefore was set to default '$outfile'");
    }


    if (!defined($indir)){

        $indir = File::Spec->rel2abs(cwd());

        printYellow("--indir was not specified and therefore was set to default '$indir'");
    }
    else {
        checkIndirStatus($indir);
    }


    my $fatalCtr = 0;


    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    }

}

sub checkIndirectoryStatus {

    my ($indir) = @_;

    if (!defined($indir)){
        die ("indir was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $indir){

        printBoldRed("input directory '$indir' does not exist\n");

        $errorCtr++;
    }
    else {

        if (!-d $indir){

            printBoldRed("'$indir' is not a regular directory\n");

            $errorCtr++;
        }

        if (!-r $indir){

            printBoldRed("input directory '$indir' does not have read permissions\n");

            $errorCtr++;
        }
    }

    if ($errorCtr > 0){

        printBoldRed("Encountered issues with input directory '$indir'\n");

        exit(1);
    }
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

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub checkInfileStatus {

    my ($infile) = @_;

    if (!defined($infile)){
        die ("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){
        print color 'bold red';
        print ("input file '$infile' does not exist\n");
        print color 'reset';
        $errorCtr++;
    }
    else {

        if (!-f $infile){
            print color 'bold red';
            print ("'$infile' is not a regular file\n");
            print color 'reset';
            $errorCtr++;
        }

        if (!-r $infile){
            print color 'bold red';
            print ("input file '$infile' does not have read permissions\n");
            print color 'reset';
            $errorCtr++;
        }

        if (!-s $infile){
            print color 'bold red';
            print ("input file '$infile' does not have any content\n");
            print color 'reset';
            $errorCtr++;
        }
    }

    if ($errorCtr > 0){
        print color 'bold red';
        print ("Encountered issues with input file '$infile'\n");
        print color 'reset';
        exit(1);
    }
}

sub main {

    my $file_list = execute_cmd("find $indir -type f");

    my $file_ctr = 0;
    my $rec_ctr = 0;

    open (OUTFILE, ">$outfile") || $logger->logconfess("Could not open '$outfile' in write mode : $!");

    print OUTFILE "## method-created: ". File::Spec->rel2abs($0) . "\n";
    print OUTFILE "## date-created: " . localtime() . "\n";
    print OUTFILE "## indir: " . $indir . "\n";

    for my $file (@{$file_list}){

        $file_ctr++;

        if ($file =~ /\.bak$/){
            next;
        }

        if ($file =~ /\.git/){
            next;
        }

        my $cmd = "md5sum $file";
        my $results = execute_cmd($cmd);
        my $result = $results->[0];
        my ($checksum, $filename) = split(/\s+/, $result);

        $rec_ctr++;

        print OUTFILE "$checksum\t $file\n";
    }

    close OUTFILE;

    print "Wrote '$rec_ctr' records to '$outfile'\n";

    $logger->info("Wrote '$rec_ctr' records to '$outfile'");
}


sub execute_cmd {

    my ($cmd) = @_;

    if (!defined($cmd)){
        confess("cmd was not defined");
    }

    print "About to execute '$cmd'\n";

    my @results;

    eval {
        @results = qx($cmd);
    };

    if ($?){
        confess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @results;

    return \@results;
}