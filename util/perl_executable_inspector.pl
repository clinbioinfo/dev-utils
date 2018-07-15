#!/usr/bin/env perl
use strict;
use File::Slurp;
use File::Path;
use File::Basename;
use Term::ANSIColor;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

$|=1; ## do not buffer output stream

## Command-line arguments
my (
    $infile, 
    $outdir,
    $log_level, 
    $help, 
    $logfile, 
    $man, 
    $verbose,
    );

my $results = GetOptions (
    'log-level|d=s'  => \$log_level, 
    'logfile=s'      => \$logfile,
    'help|h'         => \$help,
    'man|m'          => \$man,
    'infile=s'       => \$infile,
    'outdir=s'       => \$outdir,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    logfile   => $logfile, 
    log_level => $log_level
    );

if (!defined($logger)){
    die "Could not instantiate DevelopmentUtils::Logger";
}

my @lines = read_file($infile);

chomp @lines;

my $line_ctr = 0;

my $sub_lookup = {};

my $sub_ctr = 0;

my $line_of_code_list = [];

foreach my $line (@lines){

	if ($line =~ m|^\s*$|){
		next;
	}

	if ($line =~ m|^\#|){
		next;
	}


	if ($line =~ m|^sub\s+(\S+)\s*\{{0,1}\s*$|){

		$sub_lookup->{$1}++;

		$sub_ctr++;

		next;
	}

	push(@{$line_of_code_list}, $line);
}


if ($sub_ctr > 0){

	
	my $used_sub_lookup = {};
	
	my $used_sub_ctr = 0;
	my $used_sub_list = [];

	my $unused_sub_ctr = 0;
	my $unused_sub_list = [];
	

	foreach my $subname (sort keys %{$sub_lookup}){

		my $found_use_of_sub = FALSE;

		foreach my $line_of_code (@{$line_of_code_list}){
			
			if ($line_of_code =~ m/$subname/){
				
				$found_use_of_sub = TRUE;

				push(@{$used_sub_list}, $subname);

				$used_sub_ctr++;

				last; 
				## Done checking for use of this subroutine.
				## Start checking for the use of the next one.
			}
		}

		if (! $found_use_of_sub){
			$unused_sub_ctr++;
			push(@{$unused_sub_list}, $subname);
		}
	}

	if ($used_sub_ctr > 0){
		printGreen("\nFound the following '$used_sub_ctr' used subroutines:");
		print join("\n", @{$used_sub_list}) . "\n";
	}

	if ($unused_sub_ctr > 0){

		printBoldRed("\nFound the following '$unused_sub_ctr' unused subroutines:");
		print join("\n", @{$unused_sub_list}) . "\n";
	}

}
else {
	print "No subroutines found in '$infile'\n";
}

printGreen(File::Spec->rel2abs($0) . " execution completed\n");


exit(0);

##-----------------------------------------------------------
##
##    END OF MAIN -- SUBROUTINES FOLLOW
##
##-----------------------------------------------------------

sub checkCommandLineArguments {
   
    if ($man){
    	&pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }
    
    if ($help){
    	&pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to '$verbose'");
    }

    if (!defined($log_level)){

        $log_level = DEFAULT_LOG_LEVEL;

        printYellow("--log_level was not specified and therefore was set to '$log_level'");
    }

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR;

        printYellow("--outdir was not specified and therefore was set to '$outdir'");
    }

    $outdir = File::Spec->rel2abs($outdir);

    if (!-e $outdir){

        mkpath ($outdir) || die "Could not create output directory '$outdir' : $!";

        printYellow("Created output directory '$outdir'");

    }
    
    if (!defined($logfile)){

    	$logfile = $outdir . '/' . File::Basename::basename($0) . '.log';

    	printYellow("--logfile was not specified and therefore was set to '$logfile'");

    }

    $logfile = File::Spec->rel2abs($logfile);


    my $fatalCtr=0;

    if (!defined($infile)){

    	printBoldRed("--infile was not specified");

    	$fatalCtr++;

    }

    if ($fatalCtr> 0 ){
    	die "Required command-line arguments were not specified\n";
    }
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

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}