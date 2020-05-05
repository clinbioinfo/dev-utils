
#!/usr/bin/env perl
use strict;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Path;
use File::Slurp;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Term::ANSIColor;

use constant FALSE => 0;
use constant TRUE => 1;
use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();
use constant DEFAULT_VERBOSE => TRUE;

my $help;
my $infile;
my $man;
my $outdir;
my $outfile;
my $verbose;

my $results = GetOptions (
    'help|h'        => \$help,
    'infile=s'      => \$infile, 
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'outfile=s'     => \$outfile,
    'verbose=s'     => \$verbose,
    );

&checkCommandLineArguments();

main();

if ($verbose){
    printGreen(File::Spec->rel2abs($0) . " execution completed");
}

exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;

    if (!defined($infile)){
        printBoldRed("--infile was not specified");
        $fatalCtr++;
    }

    if ($fatalCtr > 0){
    	die "Required command-line arguments were not specified\n";
    }

    if (!defined($verbose)){
        $verbose = DEFAULT_VERBOSE;
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
    }

    if (!defined($outdir)){
        $outdir = DEFAULT_OUTDIR;
        printYellow("--outdir was not specified and therefore was set to default '$outdir'");        
    }

    if (!-e $outdir){
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        print "Created output directory '$outdir'\n";
    }

    if (!defined($outfile)){
        my $basename = File::Basename::basename($infile);
        $basename =~ s/\.txt$//;
        $outfile = $outdir . '/install_'. $basename . '.sh';
        printYellow("--outfile was not specified and therefore was set to default '$outfile'");
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

sub main {

    if (!-e $infile){
        die "infile '$infile' does not exist";
    }

    if (!-f $infile){
        die "infile '$infile' is not a regular file";
    }

    if (!-s $infile){
        die "infile '$infile' does not have any content";
    }

    open (OUTFILE, ">$outfile") || die "Could not open file '$outfile' in write mode : $!";
    
    print OUTFILE "#!/bin/bash\n\n";

    my @content = read_file($infile);
    
    chomp @content;
    
    for my $line (@content){
    
        if ($line =~ /^Reference:\s*(.+)/){
            print OUTFILE "echo \"Reference: $1\"\n\n";
        }
        else {
            print OUTFILE "echo \"About to execute: $line\"\n";
            print OUTFILE $line . "\n\n";
        }
    }

    close OUTFILE;
    print "Wrote output file '$outfile'\n";
}