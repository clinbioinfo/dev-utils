#!/usr/bin/env perl
use strict;
use Cwd;
use File::Basename;
use Term::ANSIColor;
use Time::Piece;
use Try::Tiny;
use File::Slurp;
use Sys::Hostname;

use constant TRUE => 1;
use constant FALSE => 0;


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

my $time = sprintf("%02d%02d", $hour, $min);
my $date = localtime->strftime("%Y-%m-%d");
my $timestamp = $date . '-' . $time . '.bak';

my $username = getlogin || getpwuid($<) || $ENV{USER} || 'sundaramj';

my $username = 'root';

my $scp_conf_file = cwd() . '/scp_conf.txt';

# my $default_project_dir = File::Basename::basename(cwd());

my $target_machine;

my $target_base_dir;

# my $project_dir;

if (scalar(@ARGV) > 0){

	scp_assets();

	printGreen("$0 execution completed");

	exit(0);
}
else {

    printBoldRed("Usage : perl $0 list-of-files-or-directories");

    exit(1);
}

##----------------------------------------------------------------------
##
##   END OF MAIN -- SUBROUTINES FOLLOW
##
##----------------------------------------------------------------------

sub scp_assets {

	if (-e $scp_conf_file){

		read_scp_conf_file();

		if (! are_all_defaults_correct()){

			print "Okay, please provide the appropriate values:\n";

			prompt_user_for_values();
		}
	}
	else {

		print "Looks like there is no scp configuration file to read defaults from.\n";

		print "Please provide those values now:\n";

		prompt_user_for_values();
	}

	execute_transfer();

	write_scp_conf_file();

	transfer_file($scp_conf_file);
}

sub are_all_defaults_correct {

	my $answer;

	print "Here are the default values:\n";

	print "target machine : ";  printYellow($target_machine);

	print "target base directory : "; printYellow($target_base_dir);

	# print "project directory : "; printYellow($project_dir);

	while (1){

		print "Are all defaults correct? [Y/n] ";

		$answer = <STDIN>;

		chomp $answer;

		$answer = uc($answer);

		if ((!defined($answer)) || ($answer eq '')){

			$answer = 'Y';
		}
		if ($answer eq 'Y'){

			return TRUE;
		}
		elsif ($answer eq 'N'){

			return FALSE;
		}
	}
}

sub prompt_user_for_values {

    $target_machine = &get_answer("Which machine to send files to?", $target_machine);

    $target_base_dir = &get_answer("What is the target base directory?", $target_base_dir);

    # $project_dir = &get_answer("What is the project directory?", $default_project_dir);
}

sub execute_transfer {

	my $ctr = 0;

	my $transfer_ctr = 0;

    foreach my $file (@ARGV){

		$ctr++;

		chomp $file;

		transfer_file($file);

		$transfer_ctr++;
    }

    print "Processed '$ctr' assets\n";
    print "Transfered '$transfer_ctr' assets\n";
}

sub transfer_file {

	my ($file) = @_;


	if (-f $file){

		if (File::Basename::basename($file) eq 'scp_conf.txt'){
			$file = File::Basename::basename($file);
		}
		else {
			## Backup the target file
			my $cmd = "ssh root\@$target_machine 'cp $target_base_dir/$file $target_base_dir/$file.$timestamp'";

			execute_cmd($cmd);
		}

	    my $ex = "scp $file $username\@$target_machine:$target_base_dir/$file";

	    execute_cmd($ex);
	}
	elsif (-d $file){

	    my $ex = "scp -r $file $username\@$target_machine:$target_base_dir/$file";

	    execute_cmd($ex);
	}
	else{
	    print color 'bold red';
	    print "Don't know how to handle '$file'\n";
		print color 'reset';
	    next;
	}
}


sub execute_cmd {

	my ($ex) = @_;

	$ex =~ s|/+|/|g; ## replace multiple forward slashes with a single one

	print "About to execute '$ex'\n";

	try {

	    qx($ex);

	} catch {

	    print color 'bold red';
	    print "Encountered the following error: $_\n";
	    print color 'reset';
	    exit(1);
	};
}

sub read_scp_conf_file {

	print "Reading values from the scp configuration file '$scp_conf_file'\n";

	my @lines = read_file($scp_conf_file);

	foreach my $line (@lines){

		chomp $line;

		if ($line =~ m|^target_machine=(\S+)\s*$|){

			$target_machine = $1;
		}
		elsif ($line =~ m|^target_base_dir=(\S+)\s*$|){

			$target_base_dir = $1;
		}
		# elsif ($line =~ m|^project_dir=(\S+)\s*$|){

		# 	$project_dir = $1;
		# }
	}
}

sub write_scp_conf_file {

	open (OUTFILE, ">$scp_conf_file") || confess("Could not open '$scp_conf_file' in write mode : $!");

	print OUTFILE "target_machine=$target_machine\n";

	print OUTFILE "target_base_dir=$target_base_dir\n";

	# print OUTFILE "project_dir=$project_dir\n";

	print OUTFILE "## source-machine: " . hostname() . "\n";

	print OUTFILE "## date-created: " . localtime() . "\n";

	print OUTFILE "## created-by: " . $username . "\n";

	close OUTFILE;

	print("Wrote records to '$scp_conf_file'\n");
}

sub get_answer {

    my ($question, $default) = @_;

    my $answer;

    while (1){

	    print STDERR $question;
	    if (defined($default)){
	    	print " [";
		    print color 'yellow';
		    print $default;
		    print color 'reset';
		    print "] ";
		}
		else {
			print " ";
		}

	    $answer = <STDIN>;

	    chomp $answer;

	    if ((!defined($answer)) || ($answer eq '')){

	    	if (defined($default)){
				return $default;
			}
	    }
	    else {
			return $answer;
	    }
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