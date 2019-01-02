#!/usr/bin/env perl
use strict;
use File::Basename;
use File::Path;
use File::Slurp;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use Term::ANSIColor;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => FALSE;

## Do not buffer output stream
$|= 1;

my $help;
my $infile;
my $indir;
my $log_level;
my $logfile;
my $man;
my $outdir;
my $outfile;
my $verbose;

my $results = GetOptions (
    'help|h'        => \$help,
    'indir=s'       => \$indir,
    'infile=s'      => \$infile,
    'log_level|d=s' => \$log_level,
    'logfile=s'     => \$logfile,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'outfile=s'     => \$outfile,
    'verbose'       => \$verbose,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    logfile   => $logfile,
    log_level => $log_level
    );

if (!defined($logger)){
    die "Could not instantiate DevelopmentUtils::Logger";
}

my $master_error_ctr = 0;
my $missing_lookup = {};
my $missing_ctr = 0;
my $function_ctr = 0;

&main();

if ($verbose){

    printGreen(File::Spec->rel2abs($0) . " execution completed");

    print "The log file is '$logfile'\n";
}

exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub get_file_list {

    my $list = [];

    if (defined($infile)){
        push(@{$list}, $infile);
    }

    if (defined($indir)){

        my $cmd = "find $indir -name '*.py'";

        my $file_list = execute_cmd($cmd);

        for my $file (@{$file_list}){

            push(@{$list}, $file);
        }
    }

    return $list;
}

sub main {

    my $file_list = get_file_list();

    my $file_ctr = 0;

    for my $file (@{$file_list}){

        $file_ctr++;

        $logger->info("Processing '$file'");

        analyze_file($file);
    }

    $logger->info("Processed '$file_ctr' files");

    if ($verbose){

        print "Processed '$file_ctr' files\n";

        print "Processed '$function_ctr' functions\n";
    }

    if ($master_error_ctr > 0){
        print "'$master_error_ctr' functions were missing type hinting\n";
    }

    generate_report();
}

sub analyze_file {

    my ($file) = @_;

    if ($verbose){
        print "Processing '$file'\n";
    }

    my @contents = read_file($file);

    chomp @contents;

    my $line_ctr = 0;

    my $missing_flag = FALSE;

    for my $line (@contents){

        $line_ctr++;

        # print $line . "\n";

        if ($line =~ m/^\s*def\s+(\S+)\s*\((.+)\)\s*:/){

            $function_ctr++;

            my $function_name = $1;

            my $param_content = $2;

            $logger->info("Found a function '$function_name' with param content '$param_content'");

            if ($param_content !~ m/:/){

                $logger->info("Looks like function '$function_name' is missing type hinting");

                push(@{$missing_lookup->{$file}}, [$function_name, $line_ctr]);

                $missing_ctr++;

                $missing_flag = TRUE;
            }

            next;
        }
    }

    if ($missing_flag){
        $master_error_ctr++;
    }
}

sub generate_report {

    open (OUTFILE, ">$outfile") || $logger->logconfess("Could not open output file '$outfile' : $!");

    print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";

    print OUTFILE "## date-created: " . localtime() . "\n";

    if (defined($infile)){
        print OUTFILE "## infile: " . File::Spec->rel2abs($infile) . "\n";
    }

    if (defined($indir)){
        print OUTFILE "## indir: " . File::Spec->rel2abs($indir) . "\n";
    }

    for my $file (sort keys %{$missing_lookup}){

        print OUTFILE "\n## For file '$file', the following functions were missing type hints\n";

        for my $list (@{$missing_lookup->{$file}}){

            my $function_name = $list->[0];

            my $line_number = $list->[1];

            print OUTFILE "function '$function_name' at line '$line_number'\n";
        }
    }

    close OUTFILE;

    $logger->info("Wrote report file '$outfile'");

    print "Wrote report file '$outfile'\n";
}

sub execute_cmd {

    my ($ex) = @_;

    $logger->info("About to execute '$ex'");

    print "About to execute '$ex'\n";

    my @result;

    eval {
        @result = qx($ex);
    };

    if ($?){
        $logger->logconfess("Encountered some error while attempting to execute '$ex' : $! $@");
    }

    chomp @result;

    return \@result;
}

sub checkCommandLineArguments {


    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    if (!defined($log_level)){

        $log_level = DEFAULT_LOG_LEVEL;

        printYellow("--log_level was not specified and therefore was set to '$log_level'");
    }

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR;

        printYellow("--outdir was not specified and therefore was set to default '$outdir'");
    }

    if (!-e $outdir){
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        print "Created output directory '$outdir'\n";
    }

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
    }

    if (!defined($logfile)){

        $logfile = $outdir . '/' . File::Basename::basename($0) . '.log';

        printYellow("--logfile was not specified and therefore was set to '$logfile'");

    }

    $logfile = File::Spec->rel2abs($logfile);

    if (!defined($outfile)){

        $outfile = $outdir . '/' . File::Basename::basename($0) . '.txt';

        printYellow("--outfile was not specified and therefore was set to '$outfile'");

    }

    $outfile = File::Spec->rel2abs($outfile);

    my $fatalCtr = 0;


    if ((!defined($infile)) && (!defined($indir))){

        printBoldRed("You must specify --infile or --indir");

        $fatalCtr++;
    }

    if ($fatalCtr > 0){
        die "Required command-line arguments were not specified\n";
    }

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

__END__

=head1 NAME

 python_type_hints.pl - Check the functions in Python program files for type hints

=head1 SYNOPSIS

 perl bin/python_type_hints.pl --infile src/my_python_program.py
 perl bin/python_type_hints.pl --indir src

=head1 OPTIONS

=over 8

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--infile>

  Path to Python file to be analyzed

=item B<--indir>

  Path to directory containing Python files (*.py) to be analyzed

=item B<--logfile>

  The Log4perl log file
  Default is [outdir]/python_type_hints.pl.log

=item B<--log_level>

  The Log4perl logging level
  Default is 4 i.e.: INFO

=item B<--man|-m>

  Prints the manual page and exits.

=item B<--outdir>

  The output directory were the logfile will be written to.
  Default is '/tmp/python_type_hints.pl/[time]/'

=item B<--verbose>

  If set to true (i.e.: 1) then will print more details to STDOUT.
  Default is false (i.e.: 0)

=back

=head1 DESCRIPTION

  This program will analyze the functions in Python program files for type hints.

=head1 CONTACT

 Jaideep Sundaram

  Copyright Jaideep Sundaram 2019

 Can be distributed under GNU General Public License terms

=cut