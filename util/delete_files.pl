#!/usr/bin/env perl
use strict;
use Term::ANSIColor;
use File::Slurp;

my $file = $ARGV[0];

if (!defined($file)){
	die "Usage : perl $0 delete-list-file\n";
}

my @files = read_file($file);

my $ctr = 0;

my $deleted_file_ctr = 0;

foreach my $delete_file (@files){

	chomp $delete_file;
	
	$ctr++;

	if (-e $delete_file){

		printYellow("Will attempt to delete '$delete_file'");

		unlink($delete_file) || die "Could not delete '$delete_file' : $!";

		$deleted_file_ctr++;
	}
	else {

		print "File '$delete_file' does not exist\n";
	}
}

print "Processed '$ctr' files\n";
print "Deleted '$deleted_file_ctr' files\n";
exit(0);

##--------------------------------------------------------------
##
##     END OF MAIN -- SURBOUTINES FOLLOW
##
##--------------------------------------------------------------

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}