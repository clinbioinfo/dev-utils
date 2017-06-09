#!/usr/bin/perl
use strict;
use File::Slurp;
use Carp;
use Term::ANSIColor;
use Data::Dumper;
use File::Spec;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;
use constant FALSE => 0;

my (
    $man,
    $help,
    $component,
    );

my $results = GetOptions (
    'help|h'       => \$help,
    'man|m'        => \$man,
    'component=s'  => \$component
    );

&checkCommandLineArguments();

my $dir = get_directory();

my $instance_outdir = get_instance_outdir($dir);

my $file_list = get_file_list($instance_outdir);

my $file_count = scalar(@{$file_list});

print "Found the following '$file_count':\n";

foreach my $file (@{$file_list}){

    print $file . " ";

    if ($file =~ /\.stderr$/){
        report_stderr_details($file);
    }
    elsif ($file =~ /\.log$/){
        report_log_details($file);
    }

    print "\n";
}

printGreen(File::Spec->rel2abs($0) . " execution completed");

exit(0);

##--------------------------------------------------------------
##
##     END OF MAIN -- SURBOUTINES FOLLOW
##
##--------------------------------------------------------------

sub checkCommandLineArguments {
   
    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }
    
    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    my $fatalCtr = 0;

    if (!defined($component))        {
        printBoldRed("--component was not specified");
        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}

sub get_directory {

    my $cmd = "ls -ltr /var/www/html/ | grep bdm | grep $component";

    my $dir_list = execute_cmd($cmd);

    my $count = scalar(@{$dir_list});

    my $line = $dir_list->[$count-1];

    my @parts = split(/\s+/, $line);

    my $dir = $parts[8];

    my $component_dir = '/var/www/html/' . $dir;

    check_directory($component_dir);

    return $component_dir;
}

sub get_instance_outdir {

    my ($component_dir) = @_;

    my $output_repository = $component_dir . '/output';

    check_directory($output_repository);

    my $cmd = "ls -ltr $output_repository";

    my $dir_list = execute_cmd($cmd);

    my $count = scalar(@{$dir_list});

    my $line = $dir_list->[$count-1];

    my @parts = split(/\s+/, $line);

    my $dir = $parts[8];

    my $instance_dir = $output_repository . '/' . $dir;

    check_directory($instance_dir);

    return $instance_dir;
}

sub get_file_list {

    my ($dir) = @_;

    my $cmd = "find $dir -type f";

    return execute_cmd($cmd);
}

sub check_directory {

    my ($dir) = @_;

    if (!-e $dir){
        confess "'$dir' does not exist";
    }

    if (!-d $dir){
        confess "'$dir' is not a directory";
    }
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

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub checkInfileStatus {

    my ($infile) = @_;

    if (!defined($infile)){
        die ("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){
        
        printBoldRed("input file '$infile' does not exist\n");
        
        $errorCtr++;
    }
    else {

        if (!-f $infile){
        
            printBoldRed("'$infile' is not a regular file\n");
            
            $errorCtr++;
        }

        if (!-r $infile){
            
            printBoldRed("input file '$infile' does not have read permissions\n");
            
            $errorCtr++;
        }
        
        if (!-s $infile){
            
            printBoldRed("input file '$infile' does not have any content\n");
            
            $errorCtr++;
        }
    }
     
    if ($errorCtr > 0){
        
        printBoldRed("Encountered issues with input file '$infile'\n");
        
        exit(1);
    }
}

sub execute_cmd {

    my ($ex) = @_;

    print "About to execute '$ex'\n";

    my @results;

    eval {
        @results = qx($ex);
    };

    if ($?){
        confess("Encountered some error while attempting to execute '$ex' : $! $@");
    }

    chomp @results;

    return \@results;
}

sub report_log_details {

    my ($file) =  @_;

    my @lines = read_file($file);

    my $count = scalar(@lines);

    my $lookup = {};

    my $uniq_ctr = 0;
    my $error_ctr = 0;
    my $info_ctr = 0;
    my $warn_ctr = 0;
    my $fatal_ctr = 0;
    my $debug_ctr = 0;

    foreach my $line (@lines){

        chomp $line;

        if ($line =~ m|^\s*ERROR|){
            $error_ctr++;
        }
        elsif ($line =~ m|^\s*INFO|){
            $info_ctr++;
        }
        elsif ($line =~ m|^\s*WARN|){
            $warn_ctr++;
        }
        elsif ($line =~ m|^\s*FATAL|){
            $fatal_ctr++;
        }
        elsif ($line =~ m|^\s*DEBUG|){
            $debug_ctr++;
        }

        if (!exists $lookup->{$line}){
            $lookup->{$line}++;
            $uniq_ctr++;
        }
    }

    print " line count '$count' unique lines count '$uniq_ctr'";
    
    if ($fatal_ctr > 0){
        print color 'red';
        print " FATAL: '$fatal_ctr'";        
        print color 'reset';
    }
    if ($error_ctr > 0){
        print color 'orange';
        print " ERROR: '$error_ctr'";        
        print color 'reset';
    }
    if ($warn_ctr > 0){
        print color 'yellow';
        print " WARN: '$warn_ctr'";        
        print color 'reset';
    }
    if ($info_ctr > 0){
        print " INFO: '$info_ctr'";        
    }
    if ($debug_ctr > 0){
        print " DEBUG: '$debug_ctr'";        
    }
}

sub report_stderr_details {

    my ($file) =  @_;

    my @lines = read_file($file);

    my $count = scalar(@lines);

    if ($count > 0){
        my $lookup = {};

        my $uniq_ctr = 0;

        foreach my $line (@lines){

            chomp $line;

            if (!exists $lookup->{$line}){
                $lookup->{$line}++;
                $uniq_ctr++;
            }
        }

        print " line count '$count' unique lines count '$uniq_ctr'";
    }
    else {
        print " (empty)";
    }
}
