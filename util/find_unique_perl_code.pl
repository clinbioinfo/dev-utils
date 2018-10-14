#!/usr/bin/perl
use strict;
use Carp;
use File::Path;
use Term::ANSIColor;
use Data::Dumper;
use File::Basename;
use File::Spec;
use File::Slurp;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

my (
    $man,
    $help,
    $outfile,
    $outdir,
    $indir
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'outfile=s'     => \$outfile,
    'indir=s'       => \$indir
    );

&checkCommandLineArguments();

my $lookup = {};

my $line_ctr = 0;

main();

printGreen(File::Spec->rel2abs($0) . " execution completed");

exit(0);

##--------------------------------------------------------------
##
##     END OF MAIN -- SURBOUTINES FOLLOW
##
##--------------------------------------------------------------

sub checkCommandLineArguments {

    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR;

        printYellow("--outdir was not specified and therefore was set to '$outdir'");
    }

    if (!-e $outdir){

        mkpath($outdir) || die "Could not create directory '$outdir'";

        printYellow("Created output directory '$outdir'");
    }

    if (!defined($outfile)){

        $outfile = DEFAULT_OUTDIR . '/report.txt';

        printYellow("--outfile was not specified and therefore was set to '$outfile'");
    }


    my $fatalCtr = 0;

    if (!defined($indir)){

        printBoldRed("--indir was not specified");

        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
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

sub checkInfileStatus {

    my ($infile) = @_;

    if (!defined($infile)){
        die ("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){

        printBoldRed("input file '$infile' does not exist\n");

        $errorCtr++;
    }
    else {

        if (!-f $infile){

            printBoldRed("'$infile' is not a regular file\n");

            $errorCtr++;
        }

        if (!-r $infile){

            printBoldRed("input file '$infile' does not have read permissions\n");

            $errorCtr++;
        }

        if (!-s $infile){

            printBoldRed("input file '$infile' does not have any content\n");

            $errorCtr++;
        }
    }

    if ($errorCtr > 0){

        printBoldRed("Encountered issues with input file '$infile'\n");

        exit(1);
    }
}

sub main {

    my $cmd = "find $indir -name '*.pm' -exec cat {} \\; | sort | uniq -c ";

    my $list1 = execute_cmd($cmd);

    load_lookup($list1);

    my $cmd2 = "find $indir -name '*.pl -exec cat {} \\; | sort | uniq -c '";

    my $list2 = execute_cmd($cmd2);

    load_lookup($list2);

    print "Processed '$line_ctr' unique lines\n";

    generate_report();
}

sub generate_report {


    open (OUTFILE, ">$outfile") || confess("Could not open '$outfile' in write mode : $!");

    print OUTFILE "## method-created: ". File::Spec->rel2abs($0) . "\n";

    print OUTFILE "## date-created: " . localtime() . "\n";

    print OUTFILE "## indir: " . File::Spec->rel2abs($indir) . "\n";

    for my $line (reverse sort {$lookup->{$a} <=> $lookup->{$b}} keys %{$lookup}){

        print OUTFILE $lookup->{$line} . " - " . $line . "\n";
    }

    close OUTFILE;

    print ("Wrote records to '$outfile'\n");

}



sub load_lookup {

    my ($list) = @_;

    for my $line (@{$list}){

        $line_ctr++;

        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ($line =~ /^(\d+)\s+(.+)$/){
            $lookup->{$2} += $1;
        }
        # print ">$line<\n";
    }

    # die "asdfsdF";
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