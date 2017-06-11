#!/usr/bin/perl
use strict;
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
    $log_file,
    $levels
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'log_file=s'    => \$log_file,
    'levels=s'      => \$levels
    );

&checkCommandLineArguments();

my $level_lookup = {};

if (defined($levels)){
    _process_levels();
}

my @lines = read_file($log_file);

my $count = scalar(@lines);

if ($count > 0){
    process_lines(\@lines);
}
else {
    print "No lines in file '$log_file'\n";    
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

    if (!defined($log_file)){
       
        printBoldRed("--log_file was not specified");

        $fatalCtr++;
    }

    $log_file = File::Spec->rel2abs($log_file);
        
    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}

sub process_lines {

    my ($lines) = @_;

    my $line_ctr = 0;

    foreach my $line (@{$lines}){

        $line_ctr++;

        ## e.g.:
        ## INFO - [458 | 2017/06/11 10:33:24 | asdev0125.medimmune.com | 20630] /var/www/html/bdm-etl-console-core-repo-v1.1-3.5.1-bdmdev2-dbqas0030/lib/MedImmune/BDM/Database/Config/Record.pm 132 Instantiated MedImmune::BDM::Database::Config::Record
        if ($line =~ /^(FATAL|ERROR|WARN|INFO|DEBUG)\s+\-\s+\[\d+.+\d+\]\s+\S+\s+\d+\s+(.+)\s*$/){

            my $level = $1;

            my $content = $2;

            if (defined($levels)){
                if (exists $level_lookup->{$level}){

                    if (($level eq 'FATAL') || ($level eq 'ERROR')){
                        print color 'red';
                        print $level;
                        print color 'reset';
                    }
                    elsif ($level eq 'WARN'){
                        print color 'red';
                        print $level;
                        print color 'reset';
                    }
                    else {
                        print $level;
                    }

                    if ($level eq 'FATAL'){

                        if ($content =~ m|line (\d+)\s*$|){
                            
                            my $at_line = $1;
                            
                            $content =~ s|line \d+\s*$||;
                            
                            print ' - ' . $content;
                            
                            print color 'yellow';
                            print "line $at_line\n";
                            print color 'reset';
                        }    

                    }
                    else {
                        print ' - ' . $content . "\n";
                    }
                }
            }
            else {
                print $level . ' - ' . $content . "\n";
            }
        }
        else {
            die "Unexpected content '$line' at line '$line_ctr'";
        }
    }
}

sub _process_levels {

    my @parts = split(',', $levels);

    foreach my $level (@parts){
        $level =~ s|\s||g;
        $level_lookup->{$level}++;
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