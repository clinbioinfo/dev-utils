#!/usr/bin/env perl
use strict;
use Cwd;
use File::Spec;
use Term::ANSIColor;
use FindBin;
use File::Copy;
use File::Path;
use File::Compare;
use Sys::Hostname;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

use constant USERNAME => $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_HISTORY_DIRECTORY => '/home/' . USERNAME . '/my-history';

my $help;
my $man;
my $verbose;
my $test_mode;
my $outdir;
my $config_file;
my $log_file;
my $log_level;
my $target_file;
my $comment;
my $tags;
my $history_directory;


my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'config_file=s' => \$config_file,
    'comment=s'     => \$comment,
    'tags=s'        => \$tags,
    'history_directory=s' => \$history_directory, 
    );

&checkCommandLineArguments();


my $logger = DevelopmentUtils::Logger::getInstance(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

main();


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

sub get_history_v1 {

    my @history;

    eval {
	@history = qx("history");
    };
    
    if ($?){
	$logger->logconfess("Encountered some error while attempting to execute 'history' : $! $@");
    }

    chomp @history;

    return \@history;
}

sub get_history {

    my @history;

    while (my $line = <STDIN>){
	print $line;
	chomp $line;
	push(@history, $line);
    }
    my $history = <STDIN>;
 
    chomp @history;

    return \@history;
}

sub main { 

    my $history = &get_history();
    
    my $date = localtime();
    
    my $outfile = $history_directory . '/' . time() . '.txt';

	
    open (OUTFILE, ">$outfile") || $logger->logconfess("Could not open output file '$outfile' in write mode : $!");

    print OUTFILE "## date-created : " . $date . "\n";
    print OUTFILE "## machine : " . hostname() . "\n";
    print OUTFILE "## directory : " . File::Spec->rel2abs(cwd()) . "\n";
    
    if (defined($comment)){
	print OUTFILE "## comment: $comment\n";
    }

    if (defined($tags)){
	print OUTFILE "## tags: $tags\n";
    }

    my $history = get_history();
    
    print OUTFILE join("\n", @{$history});

    close OUTFILE;

    $logger->info("Wrote history file '$outfile'");
    
    print "Wrote history file '$outfile'\n";
}


sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;


    if ($fatalCtr > 0){
    	die "Required command-line arguments were not specified\n";
    }


    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;
        
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
        
    }


    if (!defined($history_directory)){

        $history_directory = DEFAULT_HISTORY_DIRECTORY;
        
        printYellow("--history_directory was not specified and therefore was set to default '$history_directory'");
        
    }

    if (!-e $history_directory){

	mkpath($history_directory) || printBoldRed("Could not create history directory '$history_directory' : $!");

	printYellow("Created history directory '$history_directory'");
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
