#!/usr/bin/env perl
use strict;
use File::Slurp;

my $infile = $ARGV[0];
if (!defined($infile)){
    die "Usage : perl $0 infile\n";
}

my @lines = read_file($infile);

chomp @lines;

foreach my $line (@lines){
    create_method_code($line);
}

print "$0 execution completed\n";
exit(0);


sub create_method_code {
    my ($line) = @_;

    if ($line =~ m/^\s*\$self->(_\S+)\(.*\);\s*$/){
        # print "Found method '$1'\n";
        write_method_code($1);
    }
    else {
        die "Could not parse line '$line'";
    }
}

sub write_method_code {

    my ($method) = @_;
    print 'sub ' . $method . ' {' . "\n\n";
    print '    my $self = shift;' . "\n\n";
    print '}' . "\n\n";

}