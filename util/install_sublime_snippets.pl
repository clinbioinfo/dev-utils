#!/usr/bin/env perl
use strict;
use Term::ANSIColor;
use FindBin;
use File::Copy;
use File::Compare;

use constant DEFAULT_INSTALL_DIR => '~/.config/sublime-text-3/Packages/User/';
use constant DEFAULT_SOURCE_DIR => "$FindBin::Bin/../sublime-snippets/snippets/";

my $source_dir = $ARGV[0];
if (!defined($source_dir)){
	$source_dir = DEFAULT_SOURCE_DIR
}
if (!-e $source_dir){
	die "source directory '$source_dir' does not exist";
}

my $install_dir = $ARGV[1];
if (!defined($install_dir)){
	$install_dir = DEFAULT_INSTALL_DIR;	
}

if (!-e $install_dir){
	die "install directory '$install_dir' does not exist";
}

my $file_list = get_file_list();

my $file_ctr = 0;
my $copy_ctr = 0;
my $already_exists_ctr = 0;
my $already_exists_list = [];

foreach my $file (@{$file_list}){

	$file_ctr++;
	
	my $target_file = $install_dir . '/' . File::Basename::basename($file);

	if (!-e $target_file){

		copy($file, $target_file) || die "Encountered some error while attempting to copy file '$file' to '$target_file' : $!";
		
		$copy_ctr++;
	}
	else {

		if (compare($file, $target_file) == 0){

			$already_exists_ctr++;

			push(@{$already_exists_list}, $file);

		}
		else {

			print "target file '$target_file' already exists\n";

			printYellow("The contents are different");

			print "You might want to compare the contents of both files and make a decision how you want to proceed\n";

			print "diff $file $target_file | less\n\n";
		}
	}
}

print "Processed '$file_ctr' Sublime snippet files\n";

print "Copied '$copy_ctr' files from '$source_dir' to '$install_dir'\n";

if ($already_exists_ctr > 0){

	printYellow("The following '$already_exists_ctr' Sublime snippet files existed in the target install directory and have the same content:");

	print join("\n",  @{$already_exists_list}) . "\n";
}

print "$0 execution completed\n";
exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub get_file_list {

	my $cmd = "find $source_dir -name '*.sublime-snippet'";

	my @file_list;

	print "About to execute '$cmd'\n";

	eval {
		@file_list = qx($cmd);
	};

	if($?){
		die "Encountered some error while attempting to execute '$cmd' : $! $@";
	}

	chomp @file_list;

	return \@file_list;
}