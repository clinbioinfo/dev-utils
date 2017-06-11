#!/usr/bin/perl
use strict;
use Cwd;
use Term::ANSIColor;
use Data::Dumper;
use File::Spec;
use File::Slurp;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;
use constant FALSE => 0;

my (
    $man,
    $help,
    $indir,
    $module
    );

my $results = GetOptions (
    'help|h'     => \$help,
    'man|m'      => \$man,
    'indir=s'    => \$indir,
    'module=s'   => \$module
    );

&checkCommandLineArguments();

my $module_file_list = get_module_file_list();

my $lookup = {};
my $use_ctr = 0;
my $uniq_use_ctr = 0;
my $uniq_use_module_lookup = {};

my $module_ctr = 0;

foreach my $module_file (@{$module_file_list}) {

    $module_ctr++;

    analyze_module_file($module_file);
}

print "Processed '$module_ctr' modules in directory '$indir'\n";

generate_report();

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

    if (!defined($module)){
       
        printBoldRed("--module was not specified");

        $fatalCtr++;
    }

    if (!defined($indir)){

        $indir = File::Spec->rel2abs(cwd());

        printYellow("--indir was not specified and therefore was set to '$indir'");
    }
       
    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}

sub analyze_module_file {

    my ($module_file) = @_;

    $module_file = File::Spec->rel2abs($module_file);

    my @lines = read_file($module_file);

    my $current_package_name;
    
    my $line_ctr = 0;

    foreach my $line (@lines){

        $line_ctr++;

        if ($line_ctr == 1){

            if ($line =~ m|^package (\S+)\;\s*$|){

                $current_package_name = $1;

                if ($current_package_name eq $module){
                    print "Found '$module' - skipping\n";
                    last;
                }

                next;
            }
        }
        else {

            if ($line =~ m|^__END__\s*$|){
                last;
            }
            
            if ($line =~ m|$module|){

                if (!exists $uniq_use_module_lookup->{$current_package_name}){
                
                    $uniq_use_ctr++;
                
                    $uniq_use_module_lookup->{$current_package_name} = $module_file;
                }

                push(@{$lookup->{$current_package_name}}, [$line_ctr, $line]);
                
                $use_ctr++;
            }
        }
    }
}

sub get_module_file_list {

    my $cmd = "find $indir -name '*.pm'";

    my $list = execute_cmd($cmd);

    return $list;
}

sub execute_cmd {
    
    my ($cmd) = @_;

    if (!defined($cmd)){
        confess("cmd was not defined");
    }

    print "About to execute '$cmd'\n";

    my @results;

    eval {
        @results = qx($cmd);
    };

    if ($?){
        confess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @results;
    
    return \@results;
}   

sub generate_report {

    if ($use_ctr > 0){

        print "\nThe module '$module' is used '$use_ctr' times in the following '$uniq_use_ctr' modules:\n";

        foreach my $package_name (sort keys %{$lookup}){

            my $module_file = $uniq_use_module_lookup->{$package_name};

            my $line_list = $lookup->{$package_name};

            printYellow("\n$package_name in file:");
            print "$module_file at line(s)\n\n";

            foreach my $ref (@{$line_list}){

                print "\t$ref->[0]\t$ref->[1]";
            }
        }
    }
    else {
        printYellow("Looks like no modules in directory '$indir' depend on module '$module'");
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

sub checkIndirectoryStatus {

    my ($indir) = @_;

    if (!defined($indir)){
        die ("indir was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $indir){
        
        printBoldRed("input directory '$indir' does not exist\n");
        
        $errorCtr++;
    }
    else {

        if (!-d $indir){
        
            printBoldRed("'$indir' is not a regular directory\n");
            
            $errorCtr++;
        }

        if (!-r $indir){
            
            printBoldRed("input directory '$indir' does not have read permissions\n");
            
            $errorCtr++;
        }        
    }
     
    if ($errorCtr > 0){
        
        printBoldRed("Encountered issues with input directory '$indir'\n");
        
        exit(1);
    }
}