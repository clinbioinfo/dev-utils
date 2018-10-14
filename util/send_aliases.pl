#!/usr/bin/env perl
use strict;
use Cwd;
use File::Copy;
use File::Basename;
use Term::ANSIColor;
use File::Slurp;
use Sys::Hostname;
use File::Temp qw(tempfile);

use constant TRUE => 1;
use constant FALSE => 0;

# my $username = getlogin || getpwuid($<) || $ENV{USER} || 'sundaramj';
my $username = 'root';

my $scp_conf_file = cwd() . '/scp_conf.txt';

my $aliases_file = $ENV{HOME} . '/dev-utils/doc/remote_aliases.txt';

if (!-e $aliases_file){
	die "'$aliases_file' does not exist";
}

my $target_machine;

my $target_file = get_target_file();

add_delete_to_aliases_file();

scp_assets();

unlink($target_file) || die "Could not unlink '$target_file' : $!";

printGreen("$0 execution completed");
print "Once you log onto '$target_machine', execute the following:\n";
print "source $target_file\n\n";
print "ssh $target_machine\n";


exit(0);


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

	transfer_file();

	write_scp_conf_file();
}

sub are_all_defaults_correct {

	my $answer;

	print "Here are the default values:\n";

	print "target machine : ";  printYellow($target_machine);

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

    $target_machine = &get_answer("Which machine to send '$aliases_file' to?", $target_machine);

}

sub transfer_file {

	my $ex = "scp $target_file $username\@$target_machine:$target_file";

	$ex =~ s|/+|/|g; ## replace multiple forward slashes with a single one

	print "About to execute '$ex'\n";

	eval {

	    qx($ex);

	};

	if ($?){

	    print color 'bold red';
	    print "Encountered some exception while attempting to execute '$ex' : $! $@";
	    print color 'reset';
	    exit(1);
	}
}

sub read_scp_conf_file {

	print "Reading values from the scp configuration file '$scp_conf_file'\n";

	my @lines = read_file($scp_conf_file);

	foreach my $line (@lines){

		chomp $line;

		if ($line =~ m|^target_machine=(\S+)\s*$|){

			$target_machine = $1;
		}
	}
}

sub write_scp_conf_file {

	open (OUTFILE, ">$scp_conf_file") || confess("Could not open '$scp_conf_file' in write mode : $!");

	print OUTFILE "target_machine=$target_machine\n";

	print OUTFILE "## source-machine: " . hostname() . "\n";

	print OUTFILE "## date-created: " . localtime() . "\n";

	print OUTFILE "## created-by: " . $username . "\n";

	print OUTFILE "## infile: " . File::Spec->rel2abs($aliases_file) . "\n";

	print OUTFILE "## working directory: " . File::Spec->rel2abs(cwd()) . "\n";

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

sub get_target_file {

	my ($fh, $filename) = tempfile( DIR => '/tmp');

	return $filename;
}

sub add_delete_to_aliases_file {

	copy($aliases_file, $target_file) || die "Could not copy '$aliases_file' to '$target_file' : $!";

	print "Copied '$aliases_file' to '$target_file'\n";

	open (OUTFILE, ">>$target_file") || die "Could not open '$target_file' in append mode : $!" ;

	print OUTFILE  "rm $target_file\n";

	close OUTFILE;
}