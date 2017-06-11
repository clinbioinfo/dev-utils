#!/usr/bin/perl
use strict;
use Cwd;
use Term::ANSIColor;
use Data::Dumper;
use File::Basename;
use File::Spec;
use File::Slurp;
use File::Compare;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;
use constant FALSE => 0;

my (
    $man,
    $help,
    $file1,
    $file2
    );

my $results = GetOptions (
    'help|h'     => \$help,
    'man|m'      => \$man,
    'file1=s'    => \$file1,
    'file2=s'    => \$file2
    );

&checkCommandLineArguments();

if ($file1 eq $file2){
    
    printBoldRed("file1 '$file1' is the same as file2 '$file2'");
    
    exit(1);    
}

my $lookup1 = get_file_lookup($file1);

my $lookup2 = get_file_lookup($file2);

my $skip_ctr = 0;
my $skip_list = [];

foreach my $package_name (sort keys %{$lookup1}){

    my $module_file1 = $lookup1->{$package_name};

    if (exists $lookup2->{$package_name}){
    
        compare_module_files($package_name);
    }
    else {

        $skip_ctr++;

        push(@{$skip_list}, [$package_name, $module_file1]);

        next;
    }
}

if ($skip_ctr > 0){

    print "\nSkipped the following '$skip_ctr' modules because they dont' exist in the other code-base:\n";

    foreach my $skip_ref (@{$skip_list}){

        print "\t'$skip_ref->[0]'\tin file $skip_ref->[1]\n";
    }
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

    if (!defined($file1)){
       
        printBoldRed("--file1 was not specified");

        $fatalCtr++;
    }
    else {
        checkInfileStatus($file1);
    }

    if (!defined($file2)){
       
        printBoldRed("--file2 was not specified");

        $fatalCtr++;
    }
    else {
        checkInfileStatus($file2);
    }

      
    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}

sub get_file_lookup {

    my ($file) = @_;

    my @lines = read_file($file);

    my $lookup = {};

    foreach my $module_file (@lines){

        chomp $module_file;

        my @module_lines = read_file($module_file);

        foreach my $line (@module_lines){

            chomp $line;

            if ($line =~ m|^package (\S+);\s*$|){

                my $package_name = $1;

                print "Found '$package_name' in module file '$module_file'\n";

                $lookup->{$package_name} = $module_file;
                
                last;
            }
        }
    }

    return $lookup;
}


sub compare_module_files {

    my ($package_name) = @_;

    my $module_file1 = $lookup1->{$package_name};

    my $module_file2 = $lookup2->{$package_name};

    if (compare($module_file1, $module_file2) == 0){
        print "Contents of file '$module_file1' and '$module_file2' are the same\n\n";
    }
    else {


        print color 'yellow';
        print "\n\n*------------------------------------------------\n";
        print "*\n";
        print "* $package_name\n";
        print "*\n";
        print "*------------------------------------------------\n";
        print color 'reset';


        print "* file 1: $module_file1\n";
        print "* file 2: $module_file2\n";
        print "*\n";
        print "* diff $module_file1 $module_file2 | less\n";
        
        my $contents_lookup1 = get_contents_lookup($module_file1);

        my $contents_lookup2 = get_contents_lookup($module_file2);

        if(! compare_contents($contents_lookup1, $contents_lookup2, $module_file1, $module_file2)){
        
            compare_contents($contents_lookup2, $contents_lookup1, $module_file2, $module_file1);
        }
    }
}


sub get_contents_lookup {

    my ($module_file) = @_;

    my @lines = read_file($module_file);
    
    chomp @lines;
    
    my $lookup = {};
    
    foreach my $line (@lines){

        $line =~ s|\s+$||;  ## strip all trailing whitespace
        

        if ($line =~ m|^use|){
            
            $line =~ s|\s+| |g;  ## replace all whitespaces with a single whitespace
            
            $line =~ s|;$||;  ## strip the trailing semicolon
            
            $lookup->{use_statements}->{$line}++;
        }
        elsif ($line =~ m|^has|){
            
            $line =~ s|\s+| |g;  ## replace all whitespaces with a single whitespace
            
            $lookup->{has_statements}->{$line}++;
        }
        elsif ($line =~ m|^sub|){
            
            $line =~ s|\s+| |g;  ## replace all whitespaces with a single whitespace
            
            $line =~ s|\s*\{\s*$||;  ## strip the trailing bracket

            $lookup->{subroutines}->{$line}++;
        }
        elsif ($line =~ m|^__END__\s*$|){
            last;
        }
    }

    return $lookup;
}


sub compare_contents {

    my ($contents_lookup1, $contents_lookup2, $module_file1, $module_file2) = @_;

    my $missing_list = [];

    my $missing_ctr = 0;

    foreach my $use_statement (sort keys %{$contents_lookup1->{use_statements}}){

        if (!exists $contents_lookup2->{use_statements}->{$use_statement}){

            $missing_ctr++;

            push(@{$missing_list}, $use_statement);
        }
    }

    foreach my $has_statement (sort keys %{$contents_lookup1->{has_statements}}){

        if (!exists $contents_lookup2->{has_statements}->{$has_statement}){

            $missing_ctr++;

            push(@{$missing_list}, $has_statement);
        }
    }

    foreach my $subroutine (sort keys %{$contents_lookup1->{subroutines}}){

        if (!exists $contents_lookup2->{subroutines}->{$subroutine}){

            $missing_ctr++;

            push(@{$missing_list}, $subroutine);
        }
    }

    if ($missing_ctr > 0){

        print color 'bold red';
        print "*\n";
        print "* The following '$missing_ctr' are missing from '$module_file2'\n";
        print "*\n";
        print color 'reset';

        foreach my $missing (@{$missing_list}){
            print "\t$missing\n";
        }

        return FALSE;
    }
    else {

        print "*\n";
        print "* Contents of these files seem to match.  Please double-check.\n";
        print "*\n";

        return TRUE;
    }
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