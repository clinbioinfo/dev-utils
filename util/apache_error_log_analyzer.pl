#!/usr/bin/perl
use strict;
use Term::ANSIColor;
use Data::Dumper;
use File::Spec;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_ERROR_LOG => '/var/log/apache2/error.log';

use constant DEFAULT_ERROR_LOG_REDHAT => '/var/log/httpd/error_log';

use constant DEFAULT_LINE_COUNT => 100;

my (
    $man,
    $help,
    $error_log,
    $error_log2,
    $line_count
    );

my $results = GetOptions (
    'help|h'       => \$help,
    'man|m'        => \$man,
    'error_log=s'  => \$error_log,
    'line_count=s' => \$line_count,
    );

$error_log2 = DEFAULT_ERROR_LOG_REDHAT;

&checkCommandLineArguments();

&checkLogfileStatus($error_log);

my $currentDate;
my $currentClient;
my $currentMessage;

my $lookup = {};

my $error_ctr = 0;

analyze_error_log();

if ($error_ctr > 0){
    display_most_recent_error();
}
else {
    printGreen("Did not find any errors within the last '$line_count' lines of Apache error log '$error_log'");
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

    if (!defined($line_count)){

        $line_count = DEFAULT_LINE_COUNT;
        
        printYellow("--line_count was not specified and therefore was set to default '$line_count'");        
    }

    if (!defined($error_log)){

        $error_log = DEFAULT_ERROR_LOG;

        printYellow("--error_log was not specified and therefore was set to default '$error_log'");       
    }

    $error_log = File::Spec->rel2abs($error_log);

    if (!-e $error_log){
    
        printYellow("'$error_log' does not exist, will check for '$error_log2'");
    
        $error_log = $error_log2;
    
        if (!-e $error_log2){
            printBoldRed("'$error_log' does not exist either");
        }
    }

    &checkInfileStatus($error_log);
        
    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
    } 
}


sub analyze_error_log {

    my $lines = &getLines();

    foreach my $line (@{$lines}){

        if ($line =~ /\[notice\] caught SIGTERM, shutting down/){
            next;
        }

        if ($line =~ /\[notice\] Apache\/2\.2\.22 \(Ubuntu\) configured -- resuming normal operations/){
            next;
        }

        ## [Wed Jan 22 11:40:14 2014] [error] [client 10.10.198.190]
        if ($line =~ /^\[(.+)\] \[error\] \[client ([\d\.]+)\] (.+)$/){
            $currentDate = $1;
            $currentClient = $2;
            $currentMessage = $3;
            push(@{$lookup->{$currentDate}->{$currentClient}}, $currentMessage);
            $error_ctr++;
        }
        else {
            if ((defined($currentDate)) && (defined($currentClient))){
                push(@{$lookup->{$currentDate}->{$currentClient}}, $line);
            }
            else {
                next;
                die "current date and current client are not defined for line '$line'";
            }
        }
    }
}

sub display_most_recent_error {

    print "\n";

    print "The last date '";
    print color 'yellow';
    print $currentDate;
    print color 'reset';
    print "' (with client '";

    print color 'yellow';
    print $currentClient;
    print color 'reset';
    print "') had the following error log entries:\n";


    print "__BEGIN__\n";
    foreach my $message (@{$lookup->{$currentDate}->{$currentClient}}){
        print $message . "\n";
    }
    print "__END__\n";
}

sub checkLogfileStatus {

    if (!-e $error_log){

        die "Apache error_log '$error_log' does not exist";
    }
    else {

        if (!-r $error_log){

            print "Apache error_log '$error_log' does not have read permissions\n";

            exit(1);
        }
        
        if (!-s $error_log){

            print "Apache error_log '$error_log' does not have any content\n";

            exit(0);
        }
    }
}


sub getLines {
    
    my $ex = "tail -" . $line_count . " " . $error_log;

    my @lines;

    eval {
        @lines = qx($ex);
    };
    if ($?){
        die "Encountered some error while attempting to execute '$ex'  : $!";
    }

    chomp @lines;

    return \@lines;
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