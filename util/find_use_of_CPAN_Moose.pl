#!/usr/bin/env/ perl
use strict;
use File::Slurp;
use Cwd;

my $namespace = '';

if (!defined($namespace)){
    die "Please set the namespace";
}

my $indir = $ARGV[0];
if (!defined($indir)){
    $indir = cwd();
}


my $cmd = "find $indir -name '*.pm'";
my @results = qx($cmd);
chomp @results;
my $found_ctr = 0;
my $list = [];
my $module_ctr = 0;
for my $module (@results){
    $module_ctr++;
    # my $file = $indir . '/' . $module;
    my $file = $module;
    my @lines = read_file($file);
    for my $line (@lines){
        chomp $line;
        if ($line =~ m/^use constant /){
            next;
        }
        if ($line =~ m/^use $namespace/){
            next;
        }
        if ($line =~ m/^use Moose;/){
            push(@{$list}, $file);
            $found_ctr++;
            next;
        }
    }
}

print "Scanned '$module_ctr' modules\n";

if ($found_ctr > 0){
    print "Found '$found_ctr' modules that use Moose:\n";
    print join("\n", @{$list}) . "\n";
}
else {
    print "Did not find any modules that use Moose in directory '$indir'\n";
}