#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Data::Dumper;
use Pod::Usage;
use File::Slurp;
use File::Spec;
use File::Path;
use Term::ANSIColor;
use FindBin;

use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use constant MAX_DEPTH => 2;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => FALSE;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_ADMIN_EMAIL_ADDRESS => 'sundaram.medimmune@gmail.com';

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Mailer;

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
    $test_mode,
    $admin_email_address,
    $known_assets_list_file
    );

my $results = GetOptions (
    'log-level|d=s'                  => \$log_level, 
    'logfile=s'                      => \$logfile,
    'config_file=s'                  => \$config_file,
    'help|h'                         => \$help,
    'man|m'                          => \$man,
    'indir=s'                        => \$indir,
    'outdir=s'                       => \$outdir,
    'test_mode=s'                    => \$test_mode,
    'admin_email_address=s'          => \$admin_email_address,
    'known_assets_list_file=s'       => \$known_assets_list_file,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    logfile   => $logfile, 
    log_level => $log_level
    );

if (!defined($logger)){
    die "Could not instantiate DevelopmentUtils::Logger";
}

my $config_manager = DevelopmentUtils::Config::Manager::getInstance(config_file => $config_file);
if (!defined($config_manager)){
    $logger->logdie("Could not instantiate DevelopmentUtils::Config::Manager");
}

my $asset_lookup = load_asset_lookup();

my $asset_list = get_asset_list();

my $new_asset_ctr = 0;

my $new_asset_list = [];

my $asset_ctr = 0;

foreach my $asset (@{$asset_list}){

    $asset_ctr++;

    if (! exists $asset_lookup->{"$asset"}){

        push(@{$new_asset_list}, $asset);

        $new_asset_ctr++;

        $logger->warn("Found new/unregistered asset '$asset'");
    }
    else {
        $logger->info("Found known/registered asset '$asset'");
    }
}

print "Processed '$asset_ctr' assets\n";
print "Found '$new_asset_ctr' new/unregistered assets\n";

if ($new_asset_ctr > 0){

    $logger->warn("Found '$new_asset_ctr' assets in directory '$indir'");

    my $date = localtime();
    
    my $subject = '[' . File::Basename::basename($0) . "] found '$new_asset_ctr' new assets in diectory '$indir'";
    
    my $body = "Found the following '$new_asset_ctr' new assets in directory '$indir' on date '$date'\n";  
    
    $body .= "Processed a total of '$asset_ctr' assets.\n";
    
    $body .= "\n" . join("\n", @{$new_asset_list}) . "\n";

    my $notifier = new DevelopmentUtils::Mailer(
        to_email   => $admin_email_address,
        from_email => $admin_email_address,
        subject    => $subject,
        message    => $body);

    if (!defined($notifier)){
        $logger->logdie("Could not instantiate DevelopmentUtils::Mailer");
    }

    $notifier->sendNotification();
}

printGreen(File::Spec->rel2abs($0) . " execution completed\n");

print "The log file is '$logfile'\n";

if ($test_mode){
    printYellow("Ran in test mode.  To disable test mode, run with: --test_mode 0");
}

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

    if (!defined($indir)){

        printBoldRed("--indir was not specified");

        $fatalCtr++;
    }

    $indir = File::Spec->rel2abs($indir);

    if (!defined($known_assets_list_file)){

        printBoldRed("--known_assets_list_file was not specified");

        $fatalCtr++;
    }
    else {
        
        $known_assets_list_file = File::Spec->rel2abs($known_assets_list_file);

        checkInfileStatus($known_assets_list_file);
    }

    if ($fatalCtr> 0 ){
    	die "Required command-line arguments were not specified\n";
    }
}

sub load_asset_lookup {

    my $lookup = {};

    my @lines = read_file($known_assets_list_file);

    my $ctr = 0;

    foreach my $line (@lines){
    
        chomp $line;

        if ($line =~ m|^\s*$|){
            next;            
        } 

        if ($line =~ m|^\#|){
            next;            
        } 

        $line =~ s|\s+$||;
        $line =~ s|^\s+||;
     
        $lookup->{$line}++;
    }

    print Dumper $lookup;
    return $lookup;
}

sub get_asset_list {

    my $cmd = "find $indir -maxdepth " . MAX_DEPTH  . " -type d";

    return execute_cmd($cmd);
}


sub execute_cmd {

    my ($ex) = @_;

    $logger->info("About to execute '$ex'");

    print "About to execute '$ex'\n";
 
    my @results;

    eval {
        @results = qx($ex);
    };

    if ($?){
        $logger->logconfess("Encountered some error while attempting to execute '$ex' : $! $@");
    }

    chomp @results;

    return \@results;
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

 asset_watcher.pl - Perl script for monitoring assets in a specific directory


=head1 SYNOPSIS

 perl util/asset_watcher.pl

=head1 OPTIONS

=over 8

=item B<--indir>

  The input directory where all of the assets files will be read from.

=item B<--outdir>

  The directory where all output artifacts will be written e.g.: the log file
  if the --logfile option is not specified.
  A default value is assigned /tmp/[username]/git_asset_manager.pl/[timestamp]/

=item B<--log_level>

  The log level for Log4perl logging.  
  Default is set to 4.

=item B<--logfile>

  The Log4perl log file.
  Default is set to [outdir]/git_asset_manager.pl.log

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--man|-m>

  Prints the manual page and exits.

=item B<--master-registration-file>

  If specified, and does exist- the installed instance of the web application software will be registered in the browsable, master registration file.

=back

=head1 DESCRIPTION

 TBD

=head1 CONTACT

 Jaideep Sundaram 

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut