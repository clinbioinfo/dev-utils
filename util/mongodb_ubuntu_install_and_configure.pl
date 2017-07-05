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

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_ADMIN_EMAIL_ADDRESS => '';

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME. '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_MONGODB_SERVICE_FILE => '/etc/systemd/system/mongodb.service';

use constant DEFAULT_ENABLE_AUTOMATIC_RESTART => FALSE;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

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
    $mongodb_service_file,
    $enable_automatic_restart
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
    'mongodb_service_file=s'         => \$mongodb_service_file,
    'enable_automatic_restart'       => \$enable_automatic_restart
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

my $apt_get_update_cmd = 'sudo apt-get update';
my $apt_get_install_mongodb = 'sudo apt-get install -y mongodb';
my $systemctl_start_mongodb = 'sudo systemctl start mongodb';
my $systemctl_status_cmd = 'sudo systemctl status mongodb';
my $enable_automatic_restart_cmd = 'sudo systemctl enable mongodb';


execute_cmd($apt_get_update_cmd);

execute_cmd($apt_get_install_mongodb);

write_mongodb_service_file();

execute_cmd($systemctl_start_mongodb);

if (check_status()){

	if ($enable_automatic_restart){

		printYellow("Will attempt to enable automatic restart");
		
		$logger->info("Will attempt to enable automatic restart");
		
		execute_cmd($enable_automatic_restart_cmd);
	}
	else {
		$logger->info("Will NOT attempt to enable automatic restart");

		printYellow("Will NOT attempt to enable automatic restart (try --enable_automatic_restart)");
	}
}
else {
	$logger->logconfess("Looks like the service could not be started");
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

    if (!defined($mongodb_service_file)){

        $mongodb_service_file = DEFAULT_MONGODB_SERVICE_FILE;

        printYellow("--mongodb_service_file was not specified and therefore was set to default '$mongodb_service_file'");
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

    my $fatalCtr=0;

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

sub execute_cmd {

    my ($ex) = @_;

    if ($test_mode){

    	printYellow("Running in test mode - would have execute: '$ex'");
    }
    else {

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
}

sub write_mongodb_service_file {

	if ($test_mode){
		printYellow("Running in test mode - would have created mongodb service file '$mongodb_service_file'");
	}
	else {

		my $temp_file = '/tmp/mongodb.service';

		open (OUTFILE, ">$temp_file") || $logger->logconfess("Could not open '$temp_file' in write mode : $!");
		
		print OUTFILE "[Unit]\n";
		print OUTFILE "Description=High-performance, schema-free document-oriented database\n";
		print OUTFILE "After=network.target\n\n";

		print OUTFILE "[Service]\n";
		print OUTFILE "User=mongodb\n";
		print OUTFILE "ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf\n\n";

		print OUTFILE "[Install]\n";
		print OUTFILE "WantedBy=multi-user.target\n";

		close OUTFILE;

		$logger->info("Wrote mongodb.service file '$temp_file'");	

		if (-e $mongodb_service_file){
			
			my $bakfile = $mongodb_service_file . '.bak';

			my $cmd = "sudo mv $mongodb_service_file $bakfile";

			execute_cmd($cmd);
			
			$logger->info("Moved '$mongodb_service_file' to '$bakfile'");
		}


		my $cmd = "sudo mv $temp_file $mongodb_service_file";

		execute_cmd($cmd);
	}
}

sub check_status {

	if ($test_mode){
		return TRUE;
	}
	else {

		my $results = execute_cmd($systemctl_status_cmd);

		foreach my $line (@{$results}){

			if ($line =~ m|^\s*Active:\s+active\s+\(running\)|){

				$logger->info("Looks like the mongodb service is active and running");

				return TRUE;
			}
		}

		$logger->error("Looks like the mongodb service is not active and running");

		return FALSE;
	}
}


__END__

=head1 NAME

 mongodb_install_and_configure.pl - Perl script for installing and configuring MongoDB


=head1 SYNOPSIS

 perl util/mongodb_install_and_configure.pl

=head1 OPTIONS

=over 8

=item B<--outdir>

  The directory where all output artifacts will be written e.g.: the log file
  if the --logfile option is not specified.
  A default value is assigned /tmp/[username]/mongodb_install_and_configure.pl/[timestamp]/

=item B<--log_level>

  The log level for Log4perl logging.  
  Default is set to 4.

=item B<--logfile>

  The Log4perl log file.
  Default is set to [outdir]/mongodb_install_and_configure.pl.log

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--man|-m>

  Prints the manual page and exits.


=back

=head1 DESCRIPTION
 
 Simple program for installing and configuring MongoDB.

=head1 CONTACT

 Jaideep Sundaram 

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
