#!/usr/bin/env perl
use strict;
use Carp;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path;
use File::Slurp;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use POSIX;
use Sys::Hostname;
use Term::ANSIColor;

## Do not buffer output stream
$|=1;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_OUTDIR => '/tmp/ruo-report-automation/' . File::Basename::basename($0) . '/' . strftime "%Y-%m-%d-%H%M%S", gmtime time;

## Command-line arguments
my (
  $help,
  $logfile,
  $man,
  $outdir,
  $outfile,
  $verbose,
);

my $results = GetOptions (
    'help|h'            => \$help,
    'logfile=s'         => \$logfile,
    'man|m'             => \$man,
    'outdir=s'          => \$outdir,
    'outfile=s'         => \$outfile,
    'verbose'           => \$verbose,
    );

&checkCommandLineArguments();

my $logfile_list = [$logfile];
my $log_stack = [];

main();

print File::Spec->rel2abs($0) . " execution completed\n";
print "Please see the contents of the report file '$outfile'\n";
exit(0);

##------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##------------------------------------------------------

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

    if (!defined($outdir)){
        $outdir = DEFAULT_OUTDIR;
        printYellow("--outdir was not specified and therefore was set to default '$outdir'");
    }

    $outdir = File::Spec->rel2abs($outdir);

    if (!-e $outdir){
        mkpath ($outdir) || die "Could not create output directory '$outdir' : $!";
        printYellow("Created output directory '$outdir'");
    }

    if (!defined($outfile)){
      $outfile = $outdir . '/' . File::Basename::basename($0) . '.txt';
      printYellow("--outfile was not specified and therefore was set to '$outfile'");
    }

    $outfile = File::Spec->rel2abs($outfile);

    my $fatalCtr=0;

    if (!defined($logfile)) {
        printBoldRed("--logfile was not specified");
        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
      die "Required command-line arguments were not specified\n";
    }
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
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

sub main {

  my $logfile = shift(@{$logfile_list});
  if (!defined($logfile)){
    die "logfile was not defined";
  }

  analyze_logfile($logfile);

  while (my $subsequence_logfile = shift(@{$logfile_list})){
    analyze_logfile($subsequence_logfile);
  }

  generate_report();
}

sub generate_report {

  open (OUTFILE, ">$outfile") || die ("Could not open output file '$outfile' in write mode : $!");

  print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
  print OUTFILE "## date-created: " . localtime() . "\n";
  print OUTFILE "## server: " . Sys::Hostname::hostname() . "\n";
  print OUTFILE "## logfile: " . File::Spec->rel2abs($logfile)  . "\n";

  for my $stack (@{$log_stack}){

    my $system_call = $stack->[0];
    my $logfile = $stack->[1];
    my $stdout = $stack->[2];
    my $stderr = $stack->[3];

    print OUTFILE "\nEncountered some exception while attempting to execute:\n\n";

    my $formatted_system_call = $system_call;
    $formatted_system_call =~ s/^\'//; ## remove leading single quote
    $formatted_system_call =~ s/\'+$//; ## remove trailing single quote
    $formatted_system_call =~ s/ \-\-/\n\-\-/g;
    $formatted_system_call =~ s/ 1>/\n1>/g;
    $formatted_system_call =~ s/ 2>/\n2>/g;

    print OUTFILE $formatted_system_call . "\n\n";

    if (-e $logfile){
      if (!-s $logfile){
        print OUTFILE "The logfile '$logfile' does not have any content\n\n";
      }
    }

    if (-e $stdout){
      if (!-s $stdout){
        print OUTFILE "The stdout '$stdout' does not have any content\n\n";
      }
    }

    if (-e $stderr){
      if (!-s $stderr){
        print OUTFILE "The stderr '$stderr' does not have any content\n\n";
      }
      else {
        my @contents = read_file($stderr);
        print OUTFILE "Here are the contents of the STDERR file '$stderr':\n\n";
        print OUTFILE join("", @contents) . "\n";
      }
    }
  }
}

sub analyze_logfile {

  my ($logfile) = @_;

  checkInfileStatus($logfile);

  my @contents = read_file($logfile);

  my $line_ctr = 0;

  my $first_fatal_found = FALSE;
  my $current_system_call_encountered = FALSE;
  my $current_system_call;

  for my $line (@contents){

    $line_ctr++;

    if ($line =~ m/ About to execute (.+)/){
      $current_system_call = $1;
      $current_system_call_encountered = TRUE;
      next;
    }
    else{
      if ($line =~ m/^FATAL/){
        if ($current_system_call_encountered){
          if ($line =~ m/Encountered some error while attempting to execute (.+) : /){
            my $system_call = $1;
            if ($current_system_call =~ m/$system_call/){
              ## expected
              my ($logfile, $stdout, $stderr) = parse_system_call($current_system_call);
              push(@{$log_stack}, [$current_system_call, $logfile, $stdout, $stderr]);
              push(@{$logfile_list}, $logfile);
              $current_system_call_encountered = FALSE;
              last; ## Stop checking this log file for 'About to execute' and subsequent FATAL lines
            }
            else {
              die "current_system_call '$current_system_call' system_call '$system_call'";
            }
          }
        }
      }
    }
  }

  print "Processed '$line_ctr' in log file '$logfile'\n\n";
}

sub parse_system_call {

  my ($system_call) = @_;

  my $logfile;
  my $stdout;
  my $stderr;

  if ($system_call =~ m/--logfile (\S+)/){
    $logfile = $1;
    print "Found log file '$logfile'\n";
  }
  else {
    print "Did not find a logfile in system call '$system_call'\n";
  }

  if ($system_call =~ m/1>\s*(\S+)/){
    $stdout = $1;
    print "Found STDOUT '$stdout'\n";
  }
  else {
    print "Did not find a stdout in system call '$system_call'\n";
  }

  if ($system_call =~ m/2>\s*(\S+)/){
    $stderr = $1;
    $stderr =~ s/\'+$//; ## remove trailing single quote
    print "Found STDERR '$stderr'\n";
  }
  else {
    print "Did not find a stderr in system call '$system_call'\n";
  }

  return ($logfile, $stdout, $stderr);
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


__END__

=head1 NAME

 logfile_analyzer.pl - Parse a log file and analyze the contents

=head1 SYNOPSIS

 perl bin/logfile_analyzer.pl --logfile /tmp/my.log

=head1 REQUIRED PARAMETERS

=over 8

=item B<--logfile>

  The log file to be analyzed

=head1 OPTIONS

=over 8

=item B<--help|-h>

  Optional: Print a brief help message and exits

=item B<--man|-m>

  Prints the manual page and exits

=item B<--outdir>

  Optional: The output directory where the logfile and report file will be written to
  Default is '/tmp/logfile_analyzer.pl/[timestamp]/'

=item B<--verbose>

  Optional: If set to true (i.e.: 1) then will print more details to STDOUT
  Default is false (i.e.: 0)

=back

=head1 DESCRIPTION


  Assumptions:
  1. This software is properly installed along with its dependencies
  2. The identifier registration file contains valid data
  3. The log file is a Log4perl log file containing standard content

=head1 CONTACT

 Jaideep Sundaram

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
