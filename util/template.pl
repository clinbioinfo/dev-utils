#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Pod::Usage;
use File::Spec;
use File::Path;
use Term::ANSIColor;
use FindBin;

use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/config.ini";

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_ADMIN_EMAIL_ADDRESS => '';

#my $login =  getlogin || getpwuid($<) || "";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use MyNamespace::Logger;
use MyNamespace::Config::Manager;
use MyNamespace::Mailer;

$|=1; ## do not buffer output stream


## Command-line arguments
my (
    $indir, 
    $outdir,
    $config_file,
    $log_level, 
    $help, 
    $logfile, 
    $man, 
    $verbose,
    $admin_email_address,
    $test_mode
    );

my $results = GetOptions (
    'log-level|d=s'                  => \$log_level, 
    'logfile=s'                      => \$logfile,
    'config_file=s'                  => \$config_file,
    'help|h'                         => \$help,
    'man|m'                          => \$man,
    'indir=s'                        => \$indir,
    'outdir=s'                       => \$outdir,
    'admin_email_address=s'          => \$admin_email_address,
    'commit-push=s'                  => \$is_commit_and_push,
    'test_mode=s'                    => \$test_mode,
    );

&checkCommandLineArguments();

my $logger = new MyNamespace::Logger(
    logfile   => $logfile, 
    log_level => $log_level
    );

if (!defined($logger)){
    die "Could not instantiate MyNamespace::Logger";
}


my $config_manager = MyNamespace::Config::Manager::getInstance(config_file => $config_file);
if (!defined($config_manager)){
    $logger->logdie("Could not instantiate MyNamespace::Config::Manager");
}

&main();


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

    if (!defined($test_mode)){

        $test_mode = DEFAULT_TEST_MODE;
            
        printYellow("--test_mode was not specified and therefore was set to default '$test_mode'");
    }

    if (!defined($config_file)){

        $config_file = DEFAULT_CONFIG_FILE;
            
        printYellow("--config_file was not specified and therefore was set to '$config_file'");
    }

    &checkInfileStatus($config_file);

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to '$verbose'");
    }

    if (!defined($log_level)){

        $log_level = DEFAULT_LOG_LEVEL;

        printYellow("--log_level was not specified and therefore was set to '$log_level'");
    }

    if (!defined($admin_email_address)){

        $admin_email_address = DEFAULT_ADMIN_EMAIL_ADDRESS;

        printYellow("--admin-email-address was not specified and therefore was set to '$admin_email_address'");
    }

    if (!defined($indir)){

        $indir = DEFAULT_INDIR;

        printYellow("--indir was not specified and therefore was set to '$indir'");
    }

    $indir = File::Spec->rel2abs($indir);

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

   if (!defined($is_commit_and_push)){

        $is_commit_and_push = DEFAULT_IS_COMMIT_AND_PUSH;

        printYellow("--commit-push was not specified and therefore was set to default '$is_commit_and_push'");
    }


    my $fatalCtr=0;

    if ($fatalCtr> 0 ){
    	die "Required command-line arguments were not specified\n";
    }
}

END {

    printGreen(File::Spec->rel2abs($0) . " execution completed\n");

    print "The log file is '$logfile'\n";
    
    if ($test_mode){
	printYellow("Ran in test mode.  To disable test mode, run with: --test_mode 0");
    }

    exit(0);
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


sub checkOutdirStatus {

    my ($outdir) = @_;

    if (!-e $outdir){
        
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        
        printYellow("Created output directory '$outdir'");
    }
    
    if (!-d $outdir){

        printBoldRed("'$outdir' is not a regular directory\n");
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




__END__

=head1 NAME

 template.pl - Template for Perl programs


=head1 SYNOPSIS

 cp template.pl myprogram.pl
 edit myprogram.pl

=head1 OPTIONS

=over 8

=item B<--indir>

  The input directory where all of the source files will be read from.
  Default is two directories above the standard location of this installer
  i.e.: ../util/webInstaller.pl

=item B<--outdir>

  The directory where all output artifacts will be written e.g.: the log file
  if the --logfile option is not specified.
  A default value is assigned /tmp/[username]/webInstaller.pl/[timestamp]/

=item B<--log_level>

  The logging level for Log4perl logging.  
  Default is set to 4.

=item B<--logfile>

  The Log4perl log file.
  Default is set to [outdir]/[program name].pl.log

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--man|-m>

  Prints the manual page and exits.


=back

=head1 DESCRIPTION

 This is a template for creating new Perl programs.
 Simply copy this program file and start to edit that copy.

=head1 CONTACT

 Jaideep Sundaram 

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
