#!/usr/bin/env perl

use strict;
use Term::ANSIColor;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use FindBin;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;
use DevelopmentUtils::Git::Manager;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

my $username = $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . $username . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

my @qualified_project_list = qw|
bdm-admin-toolkit-repo
bdm-admin-operations-toolkit-repo
bdm-create-collection-repo
bdm-csv-profiler-repo
bdm-data-exploratory-portal-repo
bdm-dataset-assembly-repo
bdm-demog-synonym-template-portal-repo
bdm-etl-activity-dashboard-repo
bdm-etl-plan-and-map-repo
bdm-execute-etl-plan-repo
bdm-flatten-demog-tables-repo
bdm-publish-collection-repo
bdm-rollback-collection-repo
bdm-sql-browser-repo
bdm-stat-transfer-repo
bdm-study-documents-repo
bdm-summary-plan-repo
bdm-tng-console-repo
|;

my (
    $help, 
    $man, 
    $outdir, 
    $verbose, 
    $test_mode, 
    $log_file,
    $log_level,
    $report_file,
    $projects_conf_file,
    $config_file
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'report_file=s' => \$report_file,
    'config_file=s' => \$config_file,
    'projects_conf_file=s' => \$projects_conf_file,
    );

&checkCommandLineArguments();

my $logger = DevelopmentUtils::Logger::getInstance(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

# &promptUserCheckDependencies();

my $manager = DevelopmentUtils::Git::Branch::Manager::getInstance(
    test_mode          => $test_mode,
    verbose            => $verbose,
    config_file        => $config_file,
    outdir             => $outdir,
    projects_conf_file => $projects_conf_file,
    report_file        => $report_file
    );

if (!defined($manager)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Git::Branch::Manager");
}

$manager->determineNextBranches();

if ($verbose){
    print color 'green';
    print File::Spec->rel2abs($0) . " execution completed\n";
    print color 'reset';
}

print "The report file is '$report_file'\n";
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

    if (!defined($projects_conf_file)){

        printBoldRed("--projects_conf_file was not specified");
        
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

    if (!defined($report_file)){

        $report_file = $outdir . '/' . File::Basename::basename($0) . '.rpt';
        
        printYellow("--report_file was not specified and therefore was set to default '$report_file'");        
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

sub promptUserCheckDependencies {

    &promptAboutProjectList();

    my @questions = (
        "Have you committed all modified code in local checkouts to revision control?",
        );

    foreach my $question (@questions){

        my $answer = 'N';
        
        while (1) {

            print $question . "[y/N] ";

            $answer = <STDIN>;

            chomp $answer;

            if (uc($answer) eq 'Y'){

                last;
            }
            else{

                print "Please try again when you're ready to resume.\n";

                exit(1);
            }
        }
    }

    print ("Okay, looks like we're ready to proceed.\n");
}

sub promptAboutProjectList {

    my $count = scalar(@qualified_project_list);

    print "Here are the '$count' projects that we are going to tag:\n";

    my $ctr = 0;

    foreach my $project (sort @qualified_project_list){

        $ctr++;

        print $ctr . '. ' . $project . "\n";
    }

    my $answer = 'N';
        
    while (1) {

        print "Is this list correct? [y/N] ";
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        if (uc($answer) eq 'Y'){
            
            last;
        }
        else{

            print "Okay.  Please try again when you're ready to resume.\n";

            exit(1);
        }
    }
}