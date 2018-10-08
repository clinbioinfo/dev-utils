#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Pod::Usage;
use File::Spec;
use File::Path;
use File::Copy;
use Term::ANSIColor;
use FindBin;
use POSIX 'strftime';

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE   => FALSE;

$|=1; ## do not buffer output stream

my $path = $ARGV[0];
if (!defined($path)){
    printBoldRed("Usage : perl $0 file or directory");
    exit(1);
}

if (!-e $path){
    printBoldRed("'$path' does not exist");
    exit(1);
}

my $date = strftime '%Y-%m-%d-%H%M', localtime;

chomp $date;

my $bak = $path . '.' . $date . '.bak';

if (-f $path){
    copy($path, $bak) || die "Could not copy '$path' to '$bak' : $!";
}
else {

    my $cmd = "cp -r $path $bak";

    execute_cmd($cmd);
}

print "Copied '$path' to '$bak'\n";

exit(0);

##-----------------------------------------------------------
##
##    END OF MAIN -- SUBROUTINES FOLLOW
##
##-----------------------------------------------------------


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

sub execute_cmd {

    my ($cmd) = @_;

    eval {
	qx($cmd);
    };

    if ($?){
	die "Encountered some error while attempting to execute '$cmd' : $@ $!";
    }
}

	


__END__

=head1 NAME

 backup.pl - Perl script for backing-up a file or directory


=head1 SYNOPSIS

 perl util/backup.pl myfile.txt

=back

=head1 DESCRIPTION

 This program will create a backup for the specified file or directory.
 The backup will be given the same name with an added extension.
 That extension will comprise of the year, month and day that the back-up
 is executed.

 For example, myfile.txt will be copied to myfile.txt.2018-10-08.bak.

=head1 CONTACT

 Jaideep Sundaram 

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
