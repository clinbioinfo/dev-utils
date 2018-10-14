#!/usr/bin/perl
use strict;
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
    $log_file,
    $levels,
    $outfile,
    $outdir,
    $unexpected_file
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'log_file=s'    => \$log_file,
    'levels=s'      => \$levels,
    'outdir=s'      => \$outdir,
    'outfile=s'     => \$outfile,
    'unexpected_file=s'  => \$unexpected_file
    );

&checkCommandLineArguments();

my $level_lookup = {};

if (defined($levels)){
    _process_levels();
}

my @lines = read_file($log_file);

my $count = scalar(@lines);

if ($count > 0){
    process_lines(\@lines);
}
else {
    print "No lines in file '$log_file'\n";
}


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

    if (!defined($unexpected_file)){

        $unexpected_file = DEFAULT_OUTDIR . '/unexpected_lines.txt';

        printYellow("--unexpected_file was not specified and therefore was set to '$unexpected_file'");
    }

    if (!defined($outfile)){

        $outfile = DEFAULT_OUTDIR . '/filtered.txt';

        printYellow("--outfile was not specified and therefore was set to '$outfile'");
    }


    my $fatalCtr = 0;

    if (!defined($log_file)){

        printBoldRed("--log_file was not specified");

        $fatalCtr++;
    }

    $log_file = File::Spec->rel2abs($log_file);

    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    }
}

sub process_lines {

    my ($lines) = @_;

    my $line_ctr = 0;

    my $unexpected_ctr = 0;

    my $unexpected_list = [];

    open (OUTFILE, ">$outfile") || die "Could not open '$outfile' : $!";

    print "\n";

    foreach my $line (@{$lines}){

        chomp $line;

        $line_ctr++;

        ## e.g.:
        ## INFO - [458 | 2017/06/11 10:33:24 | asdev0125.medimmune.com | 20630] /var/www/html/bdm-etl-console-core-repo-v1.1-3.5.1-bdmdev2-dbqas0030/lib/MedImmune/BDM/Database/Config/Record.pm 132 Instantiated MedImmune::BDM::Database::Config::Record
        if ($line =~ /^(FATAL|ERROR|WARN|INFO|DEBUG)\s+\-\s+\[\d+.+\d+\]\s+(\S+)\s+(\d+)\s+(.+)\s*$/){

            my $level = $1;

            my $file = $2;

            my $line_number = $3;

            my $content = $4;

            print OUTFILE $level . ' - ' . $content . "\n";

            if ((defined($levels)) && (exists $level_lookup->{$level})){

                print $level . ' - ' . $content . "\n";
            }

            if (($level eq 'FATAL') || ($level eq 'ERROR')){
                print color 'red';
                print $level;
                print color 'reset';
            }
            elsif ($level eq 'WARN'){
                print color 'yellow';
                print $level;
                print color 'reset';
            }
            elsif ($level eq 'INFO'){
                print color 'blue';
                print $level;
                print color 'reset';
            }
            else {
                print $level;
            }

            print ' - ' . $content;

            if (($level eq 'FATAL') || ($level eq 'ERROR')){

                print color 'yellow';
                print " at line $line_number";
                print color 'reset';

                print ' ' . $file;
            }

            print "\n";

        }
        else {

            $unexpected_ctr++;

            push(@{$unexpected_list}, $line);
        }
    }

    close OUTFILE;

    print "\nWrote trimmed content to '$outfile'\n";

    if ($unexpected_ctr > 0){

        open (OUTFILE2, ">$unexpected_file") || die "Could not open '$unexpected_file' : $!";

        print OUTFILE2 join("\n", @{$unexpected_list}) . "\n";

        close OUTFILE2;

        print "Found '$unexpected_ctr' unexpected lines.  See file '$unexpected_file' for details.\n";
    }
}

sub _process_levels {

    my @parts = split(',', $levels);

    foreach my $level (@parts){
        $level =~ s|\s||g;
        $level_lookup->{$level}++;
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