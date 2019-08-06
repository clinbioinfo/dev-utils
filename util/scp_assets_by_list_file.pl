#!/usr/bin/env perl
use strict;
use Cwd;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Path;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Term::ANSIColor;
use Try::Tiny;
use File::Slurp;
use POSIX;

## Do not buffer output stream
$|=1;

use constant TRUE => 1;
use constant FALSE => 0;

# username = getlogin || getpwuid($<) || $ENV{USER} || 'sundaramj';
use constant DEFAULT_USERNAME => 'root';

use constant DEFAULT_VERBOSE => FALSE;

## Command-line arguments
my (
    $asset_list_file,
    $help,
    $man,
    $project_base_directory,
    $project_comparison_directory,
    $scp_conf_file,
    $username,
    $verbose,
    );

my $results = GetOptions (
    'asset_list_file=s'              => \$asset_list_file,
    'help|h'                         => \$help,
    'man|m'                          => \$man,
    'project_base_directory=s'       => \$project_base_directory,
    'project_comparison_directory=s' => \$project_comparison_directory,
    'scp_conf_file=s'                => \$scp_conf_file,
    'username=s'                     => \$username,
    'verbose=s'                      => \$verbose,
    );

&checkCommandLineArguments();

if (!-e $project_comparison_directory){
    mkpath($project_comparison_directory) || die "Could not create comparison directory '$project_comparison_directory' : $!";
}

my $default_project_dir = File::Basename::basename(cwd());

my $target_machine;

my $target_base_dir;

my $project_dir;

my $file_list = get_file_list($asset_list_file);

$file_list = check_all_files($file_list);

my $only_changed_files_lookup = {};

my $new_file_lookup = {};

compare_files($file_list);

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

sub checkCommandLineArguments {

    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    if (!defined($username)){

        $username = DEFAULT_USERNAME;

        printYellow("--username was not specified and therefore was set to default '$username'");
    }

    if (!defined($project_base_directory)){

        $project_base_directory = File::Basename::basename(cwd());

        printYellow("--project_base_directory was not specified and therefore was set to default '$project_base_directory'");
    }

    if (!defined($project_comparison_directory)){

        $project_comparison_directory = '/tmp/' . File::Basename::basename($0) . '/' . $project_base_directory;

        printYellow("--project_comparison_directory was not specified and therefore was set to default '$project_comparison_directory'");
    }

    if (!defined($scp_conf_file)){

        $scp_conf_file = cwd() . '/scp_conf.txt';

        printYellow("--scp_conf_file was not specified and therefore was set to default '$scp_conf_file'");
    }

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
    }

    my $fatalCtr=0;

    if (!defined($asset_list_file)) {

        printBoldRed("--asset_list_file was not specified");

        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){

        die "Required command-line arguments were not specified\n";
    }
}

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

        if (! exists $only_changed_files_lookup->{$file}){
            print "Will not attempt to transfer file '$file' because it has not changed since last the last transfer session\n";
            next;
        }

        if (exists $new_file_lookup->{$file}){

            ## This a new local project file so the parent directory does not exist on the remote server.
            ## Attempt to create the parent directory on the remote server.

            my $dirname = File::Basename::dirname($file);

            my $target_dir = $target_base_dir . '/' . $project_dir . '/' . $dirname;

            my $cmd = "ssh $username\@$target_machine \"mkdir -p $target_dir\"";

            execute_cmd($cmd);
        }

		my $ex;

		if (-f $file){

            my $target_file = $target_base_dir . '/' . $project_dir . '/' . $file;

            if (! exists $new_file_lookup->{$file}){
                ## It is not a new file so should attempt to back it up on the remote server

                my $bakfile = $target_file .  '.' . strftime "%Y-%m-%d-%H%M%S", gmtime time;

                $bakfile .= '.bak';

                my $cmd = "ssh $username\@$target_machine \"cp $target_file $bakfile\"";

                execute_cmd($cmd);
            }
            else {
                ## It is a new file so should attempt to back it up on the remote server
                print "The target file '$target_file' does not yet exist on server '$target_machine' so will not attempt to back it up\n";
            }

		    $ex = "scp $file $username\@$target_machine:$target_file";
		}
		elsif (-d $file){

            my $target_dir = $target_base_dir . '/' . $project_dir . '/' . $file;

            if (! exists $new_file_lookup->{$file}){

                my $bakdir = $target_dir .  '.' . strftime "%Y-%m-%d-%H%M%S", gmtime time;

                $bakdir .= '.bak';

                my $cmd = "ssh $username\@$target_machine \"cp $target_dir $bakdir\"";

                execute_cmd($cmd);
            }
            else {
                print "The target directory '$target_dir' does not yet exist on server '$target_machine' so will not attempt to back it up\n";
            }

		    $ex = "scp -r $file $username\@$target_machine:$target_dir";
		}
		else{
		    print color 'bold red';
		    print "Don't know how to handle '$file'\n";
			print color 'reset';
		    next;
		}

        execute_cmd($ex);

		$transfer_ctr++;

        copy_file_to_comparison_dir($file);
    }

    print "Processed '$ctr' assets\n";
    print "Transfered '$transfer_ctr' assets\n";
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

sub compare_files {

    my ($file_list) = @_;

    print "Going to compare files to those stored in the project comparison directory '$project_comparison_directory'\n";

    for my $file (@{$file_list}){

        my $path = $file;

        $path =~ s/$project_base_directory//;

        my $comparison_file = $project_comparison_directory . '/' . $path;

        if (!-e $comparison_file){
            print "comparison version file '$comparison_file' does not exist\n";
            $new_file_lookup->{$path}++;
            $only_changed_files_lookup->{$path}++;
        }
        else {
            if (compare($path, $comparison_file) == 0){
                print "file '$path' has not changed since last session\n";
            }
            else {
                print "file '$path' has changed since last session\n";
                $only_changed_files_lookup->{$path}++;
            }
        }
    }
}

sub copy_file_to_comparison_dir {

    my ($file) = @_;

    my $path = $file;

    $path =~ s/$project_base_directory//;

    my $comparison_file = $project_comparison_directory . '/' . $path;

    if (-e $comparison_file){
        print "comparison version '$comparison_file' exists and so will be removed\n";
        unlink($comparison_file) || die "Could not delete '$comparison_file' : $!";
    }

    my $comparison_dir = File::Basename::dirname($comparison_file);

    if (!-e $comparison_dir){
        mkpath($comparison_dir) || die "Could not create comparison directory '$comparison_dir' : $!";
        print "Created comparison directory '$comparison_dir'\n";
    }

    copy($path, $comparison_file) || die "Could not copy '$path' to '$comparison_file' : $!";
    print "Copied '$path' to '$comparison_file'\n";
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
