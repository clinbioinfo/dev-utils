#!/usr/bin/env perl

use strict;
use File::Slurp;
use Data::Dumper;
use Term::ANSIColor;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use FindBin;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;


use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 5;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

my (
    $help,
    $man,
    $outdir,
    $verbose,
    $test_mode,
    $log_file,
    $log_level,
    $config_file,
    $infile,
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'infile=s'      => \$infile,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

my $repo_to_module_list_lookup = {};

&main();

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

    my $fatalCtr = 0;

    if (!defined($infile)){

        printBoldRed("--infile was not specified");

        $fatalCtr++;
    }


    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
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

sub main($) {

    &checkInfileStatus($infile);

    my @repo_list = read_file($infile);

    chomp @repo_list;

    my $repo_ctr = 0;

    chdir($outdir) || $logger->logconfess("Could not change into directory '$outdir' : $!");

    $logger->info("Changed into directory '$outdir'");

    my $qualified_repo_list = [];

    for my $repo (@repo_list){

        if ($repo =~ m/^\s*$/){
            next;
        }
        if ($repo =~ m/^\#/){
            next;
        }

        $repo_ctr++;

        &check_repo($repo);

        print "\n\n";

        push(@{$qualified_repo_list}, $repo);
    }

    $logger->info("Checked '$repo_ctr' repositories described in file '$infile'");

    for my $repo (@{$qualified_repo_list}){

        if (exists $repo_to_module_list_lookup->{$repo}){

            my $modules_file_list = $repo_to_module_list_lookup->{$repo};

            my $module_file_count = scalar(@{$modules_file_list});

            print "Found '$module_file_count' Perl modules in repository '$repo'\n";
            print "Please check the log file for details\n";

            $logger->info("Found '$module_file_count' Perl modules in repository '$repo'");
            $logger->info(join("\n", @{$modules_file_list}));
        }
        else {
            print "Looks like no Perl modules were found in git repository '$repo'\n";
            $logger->info("Looks like no Perl modules were found in git repository '$repo'");
        }
    }
}

sub check_repo($){

    my ($repo) = @_;

    my $cmd = "git clone $repo";

    &execute_cmd($cmd);

    my $basename = File::Basename::basename($repo);

    $basename =~ s/\.git$//;

    my $cmd2 = "find $basename -name '*.pm'";

    my $results = &execute_cmd2($cmd2);

    if (scalar(@{$results}) > 0){
        $repo_to_module_list_lookup->{$repo} = $results;
    }

    my $cmd3 = "rm -rf $basename";

    &execute_cmd($cmd3);
}

sub execute_cmd {

    my ($ex) = @_;

    $logger->info("About to execute '$ex'");

    print "About to execute '$ex'\n";

    eval {
        qx($ex);
    };

    if ($?){
        $logger->logconfess("Encountered some error while attempting to execute '$ex' : $! $@");
    }
}

sub execute_cmd2 {

    my ($ex) = @_;

    $logger->info("About to execute '$ex'");

    print "About to execute '$ex'\n";

    my @results;

    eval {
        @results = qx($ex);
    };

    if ($?){
        $logger->logconfess("Encountered some error while attempting to execute '$ex' : $! $@");
    }

    chomp @results;

    return \@results;
}