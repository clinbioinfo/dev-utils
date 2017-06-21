#!/usr/bin/perl
use strict;
use Carp;
use Term::ANSIColor;
use File::Spec;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_WWW_BASE_DIR => '/var/www/html/';

use constant DEFAULT_WWW_BASE_URL => '';

my (
    $man,
    $help,
    $pattern,
    $base_dir,
    $base_url
    );

my $results = GetOptions (
    'help|h'       => \$help,
    'man|m'        => \$man,
    'pattern=s'    => \$pattern,
    'base_dir=s'   => \$base_dir,
    'base_url=s'   => \$base_url
    );

&checkCommandLineArguments();

if ($base_dir =~ m|/+$|){
    $base_dir =~ s|/+$|/|;
}
else {
    $base_dir .= '/';
}

my $candidate_dir = get_candidate_dir($base_dir);

print "The candidate directory is '$candidate_dir'\n";

my $file_list = get_file_list($candidate_dir);

my $file_count = scalar(@{$file_list});

if ($file_count > 0){

    print "\nFound the following '$file_count' possible entry points:\n\n";

    foreach my $file (@{$file_list}){

        my $url = $file;

        $url =~ s|$base_dir|$base_url|;

        print $file . "\n";
        print $url . "\n\n";
    }
}
else {

    printBoldRed("Did not find any candidate entry points (.html or .cgi files)");

}

printGreen("\n" . File::Spec->rel2abs($0) . " execution completed");

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


    if (!defined($base_dir)){

        $base_dir = DEFAULT_WWW_BASE_DIR;

        printYellow("--base_dir was not specified and therefore was set to default '$base_dir'");
    }

    if (!defined($base_url)){

        $base_url = DEFAULT_WWW_BASE_URL;

        printYellow("--base_url was not specified and therefore was set to default '$base_url'");
    }


    my $fatalCtr = 0;

    if (!defined($pattern))        {
        printBoldRed("--pattern was not specified");
        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}

sub get_file_list {

    my ($indir) = @_;

    my $file_list = [];

    my $html_dir = $indir . '/html';

    if (-e $html_dir){
    
        my $cmd = "find $html_dir -name '*.html'";
    
        my $results = execute_cmd($cmd);

        foreach my $file (@{$results}){
            
            push(@{$file_list}, $file);
        }
    }
    else {
        printBoldRed("'$html_dir' does not work");
    }

    my $cgi_dir = $indir . '/cgi-bin';

    if (-e $cgi_dir){
    
        my $cmd = "find $cgi_dir -name '*.cgi'";
    
        my $results = execute_cmd($cmd);

        foreach my $file (@{$results}){
        
            push(@{$file_list}, $file);
        }
    }
    else {
        printBoldRed("'$cgi_dir' does not work");
    }

    return $file_list;
}



sub get_candidate_dir {

    my $cmd = "ls -ltr $base_dir | grep $pattern";

    my $dir_list = execute_cmd($cmd);

    my $count = scalar(@{$dir_list});

    my $line = $dir_list->[$count-1]; ## look at the last one

    my @parts = split(/\s+/, $line);

    my $dir = $parts[8];

    my $candidate_dir = $base_dir . $dir;

    check_directory($candidate_dir);

    return $candidate_dir;
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

