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


    open (OUTFILE, ">$outfile") || $logger->logconfess("Could not open output file '$outfile' : $!");

    print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";

    print OUTFILE "## date-created: " . localtime() . "\n";

    if (defined($infile)){
        print OUTFILE "## infile: " . File::Spec->rel2abs($infile) . "\n";
    }

    if (defined($indir)){
        print OUTFILE "## indir: " . File::Spec->rel2abs($indir) . "\n";
    }

    for my $file (@{$file_list}){

        $file_ctr++;

        $logger->info("Processing '$file'");

        analyze_file($file);
    }

    $logger->info("Processed '$file_ctr' files");

    print OUTFILE "\n## Here are the docstring recommendations:\n";
    print_module_function_docstring_recommendations();

    print_module_docstring_recommendations();

    print_class_docstring_recommendations();

    print_class_method_docstring_recommendations();

    print OUTFILE "\n## Reference: https://realpython.com/documenting-python-code/\n";

    close OUTFILE;


    print "Wrote report file '$outfile'\n";

    print "Processed '$file_ctr' files\n";

    if ($master_error_ctr > 0){
        print "'$master_error_ctr' had some docstring problems\n";
    }

    $logger->info("Wrote report file '$outfile'");
}


sub analyze_file {

    my ($file) = @_;

    if ($verbose){
        print "Processing '$file'\n";
    }

    my @contents = read_file($file);

    chomp @contents;

    my $line_ctr = 0;

    my $line_number_lookup = {};

    my $main_docstring_found = FALSE;
    my $from_found = FALSE;
    my $import_found = FALSE;

    my $function_found = FALSE;
    my $function_ctr = 0;
    my $current_function;
    my $function_lookup = {};

    my $class_found = FALSE;
    my $class_ctr = 0;
    my $current_class;
    my $class_lookup = {};

    my $found_docstring = FALSE;

    for my $line (@contents){

        $line_ctr++;

        # print $line . "\n";

        if ($line =~ m/\#/){
            next;
        }

        if ($line =~ m/^\s*from/){

            # print ">> Found a from import statement\n";
            $from_found = TRUE;
            next;
        }

        if ($line=~ m/^\s*import/){

            # print ">> Found an import statement\n";

            $import_found = TRUE;
            next;
        }

        if ($line =~ m/^\s*def\s+(\S+)\s*\(/){

            # print ">> Found a function\n";

            $current_function = $1;
            $function_found = TRUE;
            $function_ctr++;
            $function_lookup->{$current_function} = FALSE;

            $line_number_lookup->{$current_function} = $line_ctr;

            $from_found = FALSE;
            $import_found = FALSE;
            $class_found = FALSE;

            next;
        }

        if ($line =~ m/^\s*class\s+(\S+)\s*\(/){

            # print ">> Found a class\n";

            $current_class = $1;
            $class_found = TRUE;
            $class_ctr++;
            $class_lookup->{$current_class} = FALSE;

            $line_number_lookup->{$current_class} = $line_ctr;

            $from_found = FALSE;
            $import_found = FALSE;
            $function_found = FALSE;

            next;
        }

        if ($line =~ m/^\s*\"\"\"/){

            # print ">> Found docstring\n";

            if (!$found_docstring){

                # print ">> Found beginning of docstring\n";

                $found_docstring = TRUE;

                if ($from_found || $import_found){

                    $logger->warn("Found docstring at line '$line_ctr' but only after already having found the import section!");

                    next;
                }
                elsif ($function_found){

                    $logger->info("Found docstring at line '$line_ctr' for function '$current_function'");

                    $function_lookup->{$current_function} = TRUE;

                    ## toggle this state off
                    $function_found = FALSE;
                }
                elsif ($class_found){

                    $logger->info("Found docstring at line '$line_ctr' for class '$current_class'");

                    $class_lookup->{$current_class} = TRUE;

                    ## toggle this state off
                    $class_found = FALSE;
                }
                else {
                    $main_docstring_found = TRUE;
                }
            }
            else {
                $found_docstring = FALSE;

                # print ">> Found ending of docstring\n";
            }
        }
    }


    print OUTFILE "\nAnalysis of file '$file'\n";

    my $error_ctr = 0;

    if ($main_docstring_found){

        print OUTFILE "found   : ";
    }
    else {

        print OUTFILE "missing : ";

        $error_ctr++;
    }


    print OUTFILE "for main\n";

    for my $class_name (sort keys %{$class_lookup}){

        my $found = $class_lookup->{$class_name};

        if ($found){

            print OUTFILE "found   : ";
        }
        else {

            print OUTFILE "missing : ";

            $error_ctr++;
        }

        print OUTFILE "for class '$class_name' at line '$line_number_lookup->{$class_name}'\n";
    }


    for my $function_name (sort keys %{$function_lookup}){

        my $found = $function_lookup->{$function_name};

        if ($found){

            print OUTFILE "found   : ";
        }
        else {

            print OUTFILE "missing : ";

            $error_ctr++;
        }

        print OUTFILE "for function '$function_name' at line '$line_number_lookup->{$function_name}'\n";
    }

    print $file . " was ";

    if ($error_ctr > 0){

        printBoldRed("not ok");

        $master_error_ctr++;
    }
    else {

        printGreen("ok");
    }

    $logger->info("Processed '$line_ctr' lines in file '$file'");
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


sub print_module_function_docstring_recommendations {

    print OUTFILE "\n## The docstring for a module function should include the same items as a class method:\n";
    print OUTFILE "- A brief description of what the function is and what it’s used for\n";
    print OUTFILE "- Any arguments (both required and optional) that are passed including keyword arguments\n";
    print OUTFILE "- Label any arguments that are considered optional\n";
    print OUTFILE "- Any side effects that occur when executing the function\n";
    print OUTFILE "- Any exceptions that are raised\n";
    print OUTFILE "- Any restrictions on when the function can be called\n";
}

sub print_module_docstring_recommendations {

    print OUTFILE "\n## Module docstrings should include the following:\n";
    print OUTFILE "- A brief description of the module and its purpose\n";
    print OUTFILE "- A list of any classes, exception, functions, and any other objects exported by the module\n";
}

sub print_class_docstring_recommendations {

    ## https://realpython.com/documenting-python-code/
    print OUTFILE "\n## Class docstrings should contain the following information:\n\n";
    print OUTFILE "- A brief summary of its purpose and behavior\n";
    print OUTFILE "- Any public methods, along with a brief description\n";
    print OUTFILE "- Any class properties (attributes)\n";
    print OUTFILE "- Anything related to the interface for subclassers, if the class is intended to be subclassed\n";
}

sub print_class_method_docstring_recommendations {

    print OUTFILE "\n## The class constructor parameters should be documented within the __init__ class method docstring.\n";
    print OUTFILE "Individual methods should be documented using their individual docstrings. Class method docstrings should contain the following:\n";

    print OUTFILE "- A brief description of what the method is and what it’s used for\n";
    print OUTFILE "- Any arguments (both required and optional) that are passed including keyword arguments\n";
    print OUTFILE "- Label any arguments that are considered optional or have a default value\n";
    print OUTFILE "- Any side effects that occur when executing the method\n";
    print OUTFILE "- Any exceptions that are raised\n";
    print OUTFILE "- Any restrictions on when the method can be called\n";
}


__END__

=head1 NAME

 docstring_util.pl - Check the docstrings in Python program files

=head1 SYNOPSIS

 perl bin/docstring_util.pl --infile src/my_python_program.py
 perl bin/docstring_util.pl --indir src

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
  Default is [outdir]/docstring_util.pl.log

=item B<--log_level>

  The Log4perl logging level
  Default is 4 i.e.: INFO

=item B<--man|-m>

  Prints the manual page and exits.

=item B<--outdir>

  The output directory were the logfile will be written to.
  Default is '/tmp/docstring_util.pl/[time]/'

=item B<--verbose>

  If set to true (i.e.: 1) then will print more details to STDOUT.
  Default is false (i.e.: 0)

=back

=head1 DESCRIPTION

  This program will analyze Python program files to determine whether
  the docstrings are missing.

=head1 CONTACT

 Jaideep Sundaram

  Copyright Jaideep Sundaram 2019

 Can be distributed under GNU General Public License terms

=cut