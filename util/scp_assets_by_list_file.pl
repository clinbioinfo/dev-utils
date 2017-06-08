#!/usr/bin/env perl
use strict;
use Cwd;
use File::Basename;
use Term::ANSIColor;
use Try::Tiny;
use File::Slurp;

use constant TRUE => 1;
use constant FALSE => 0;

my $username = getlogin || getpwuid($<) || $ENV{USER} || 'sundaramj';

my $scp_conf_file = cwd() . '/scp_conf.txt';

my $default_project_dir = File::Basename::basename(cwd());

my $target_machine;

my $target_base_dir;

my $project_dir;

my $asset_list_file = $ARGV[0];
if (!defined($asset_list_file)){
	printBoldRed("Usage : $0 asset-list-file");
	exit(1);
}

my $file_list = get_file_list($asset_list_file);

$file_list = check_all_files($file_list);

if (scalar(@{$file_list}) > 0){

	scp_assets();
}
else {

    printBoldRed("The asset list was empty.  Please check your file '$asset_list_file'.");
    
    exit(1);
}

printGreen("$0 execution completed");

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

	execute_transfer();

	write_scp_conf_file();
}

sub are_all_defaults_correct {

	my $answer;

	print "Here are the default values:\n";

	print "target machine : ";  printYellow($target_machine);

	print "target base directory : "; printYellow($target_base_dir);

	print "project directory : "; printYellow($project_dir);

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

    $project_dir = &get_answer("What is the project directory?", $default_project_dir);
}

sub execute_transfer {

	my $ctr = 0;

	my $transfer_ctr = 0;

    foreach my $file (@{$file_list}){
		
		$ctr++;
		
		chomp $file;
		
		my $ex;
		
		if (-f $file){
		    $ex = "scp $file $username\@$target_machine:$target_base_dir/$project_dir/$file";
		}
		elsif (-d $file){
		    $ex = "scp -r $file $username\@$target_machine:$target_base_dir/$project_dir/$file";
		}
		else{
		    print color 'bold red';
		    print "Don't know how to handle '$file'\n";
			print color 'reset';
		    next;
		}

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

		$transfer_ctr++;

    }

    print "Processed '$ctr' assets\n";
    print "Transfered '$transfer_ctr' assets\n";
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
		elsif ($line =~ m|^project_dir=(\S+)\s*$|){

			$project_dir = $1;
		}
	}
}

sub write_scp_conf_file {

	open (OUTFILE, ">$scp_conf_file") || confess("Could not open '$scp_conf_file' in write mode : $!");
	
	print OUTFILE "target_machine=$target_machine\n";

	print OUTFILE "target_base_dir=$target_base_dir\n";

	print OUTFILE "project_dir=$project_dir\n";

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

sub check_all_files {

    my ($file_list) = @_;

    my $error_list= [];

    my $error_ctr = 0;

    my $final_file_list = [];
    
    foreach my $file (@{$file_list}){

		if (!-e $file){

		    if ($file =~ m/^\s*modified:\s+(\S+)\s*$/){
			
				$file = $1;

				if (!-e $file){

				    $error_ctr++;
				    
				    push(@{$error_list}, $file);

				}
				else {
				    push(@{$final_file_list}, $file);
				}
		    }
		    else {

				$error_ctr++;

				push(@{$error_list}, $file);
		    }
		}
		else {
		    push(@{$final_file_list}, $file);
		}	    
    }

    if ($error_ctr > 0){

		print color 'bold red';
		print "The following '$error_ctr' files do not exist:\n";
		print join("\n", @{$error_list}) . "\n";
		print color 'reset';
		exit(1);
    }

    return $final_file_list;
}

sub get_file_list {

    open (INFILE, "<$asset_list_file") || die "Could not open file '$asset_list_file' : $!";

    my $file_list = [];

    my $file_ctr = 0;
    
    while (my $file = <INFILE>){


	if ($file =~ /^\#/){
	    next;
	}

	if ($file =~ /^\s*$/){
	    next;
	}
	
	$file_ctr++;

	chomp $file;

	$file =~ s/^\s+//;

	$file =~ s/\s+$//;

	push(@{$file_list}, $file);
    }

    if ($file_ctr > 0){

		print "Found '$file_ctr' files in asset list file '$asset_list_file'\n";
    }
    else {
		
		printBoldRed("Did not find any files in asset list file '$asset_list_file'");
		
		exit(1);
    }

    
    return $file_list;
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