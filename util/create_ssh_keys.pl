#!/usr/bin/env perl
use strict;
use File::Path;
use File::Copy;

my $login = getlogin || getpwuid($<) || "sundaramj";

my $ssh_dir = '/home/' . $login . '/.ssh';
my $pub_file = $ssh_dir . '/id_rsa.pub';

if (-e $pub_file){

    print "file '$pub_file' already exists\n";

    exit(0);
}
else {

    print "file '$pub_file' does not exist\n";
    
    if (!-e $ssh_dir){
	mkpath($ssh_dir) || die "Could not create directory '$ssh_dir' : $!";
    }
    
    my $email = $ARGV[0];
    if (!defined($email)){
	die "Usage : perl $0 email-address\n";
    }
    
    my $cmd = 'ssh-keygen -t rsa -C "$email"';
    
    eval {
	qx($cmd);
    };
    
    if ($?){
	die "Encountered some error while attempting to execute '$cmd' : $!";
    }

    print "$0 execution completed\n";
    exit(0);
}


