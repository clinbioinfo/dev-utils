#!/usr/bin/env perl
use strict;
use File::Basename;
use File::Path;
use File::Spec;

my $dir = $ARGV[0];
if (!defined($dir)){
	die "Usage :  perl $0 directory\n";
}


$dir = File::Spec->rel2abs($dir);

my $dirname = File::Basename::dirname($dir);
if (!-e $dirname){
	mkpath($dirname) || die "Could not create '$dirname' : $!";
	print "Created directory '$dirname'\n";
}

if ($dir =~ m/venv$/){
	## okay
}
else {
	$dir .= '-venv';
}

my $cmd = "python3 -mvenv $dir";

print "Going to create the virtual environment '$dir'\n";

print "Will execute '$cmd'\n";

eval {
	qx($cmd);
};

if ($?){
	print "Encountered some problem while attempting to execute '$cmd' : $! $@";
}

print "Created python virtual environment '$dir'\n";
print "To activate execute:\n";
print "source $dir/bin/activate\n";
exit(0);