#!/usr/bin/env perl
use strict;
use Carp;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path;
use File::Slurp;
use File::Spec;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use POSIX;
use Term::ANSIColor;

use lib "$FindBin::Bin/../lib";

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_INSERT_PROVENANCE => FALSE;

use constant DEFAULT_NO_ATTACH => FALSE;

use constant DEFAULT_INFILE => $ENV{'HOME'} . '/.config/my_server_status/server_checks.txt';

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_JIRA_CRED_FILE => $ENV{'HOME'} . '/.config/my_jira/credentials.txt';

use constant DEFAULT_JIRA_REST_URL_FILE => $ENV{'HOME'} . '/.config/my_jira/jira_rest_url.txt';

$|=1; ## do not buffer output stream

## Command-line arguments
my (
    $help,
    $infile,
    $insert_provenance,
    $issue_id,
    $jira_credentials_file,
    $jira_rest_url_file,
    $man,
    $no_attach,
    $outdir,
    $outfile,
    $server,
    $verbose,
    );

my $results = GetOptions (
    'help|h'                  => \$help,
    'infile|i=s'              => \$infile,
    'insert_provenance=s'     => \$insert_provenance,
    'issue_id=s'              => \$issue_id,
    'jira_credentials_file=s' => \$jira_credentials_file,
    'jira_rest_url_file=s'    => \$jira_rest_url_file,
    'man|m'                   => \$man,
    'no_attach'               => \$no_attach,
    'outdir=s'                => \$outdir,
    'outfile=s'               => \$outfile,
    'server=s'                => \$server,
    'verbose|v'               => \$verbose,
    );

&checkCommandLineArguments();

main();

exit(0);

##-----------------------------------------------------------
##
##    END OF MAIN -- SUBROUTINES FOLLOW
##
##-----------------------------------------------------------

sub checkCommandLineArguments {

    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    my $fatalCtr=0;

    if (!defined($server)){
        printBoldRed("--server was not specified");
        $fatalCtr++;
    }

    if (!defined($issue_id)){
        printBoldRed("--issue_id was not specified");
        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
        die "Required command-line arguments were not specified\n";
    }

    if (!defined($jira_credentials_file)){
        $jira_credentials_file = DEFAULT_JIRA_CRED_FILE;
        printYellow("--jira_credentials_file was not specified and therefore was set to default '$jira_credentials_file'");
    }

    if (!defined($jira_rest_url_file)){
        $jira_rest_url_file = DEFAULT_JIRA_REST_URL_FILE;
        printYellow("--jira_rest_url_file was not specified and therefore was set to default '$jira_rest_url_file'");
    }

    if (!defined($verbose)){
        $verbose = DEFAULT_VERBOSE;
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
    }

    if (!defined($no_attach)){
        $no_attach = DEFAULT_NO_ATTACH;
        printYellow("--no_attach was not specified and therefore was set to default '$no_attach'");
    }

    if (!defined($outdir)){
        $outdir = DEFAULT_OUTDIR;
        printYellow("--outdir was not specified and therefore was set to default '$outdir'");
    }

    if (!-e $outdir){
        mkpath($outdir) || die "Could not create directory '$outdir' : $!";
        printYellow("Created output directory '$outdir'")
    }

    if (!defined($insert_provenance)){
        $insert_provenance = DEFAULT_INSERT_PROVENANCE;
        printYellow("--insert_provenance was not specified and therefore was set to default '$insert_provenance'");
    }

    if (!defined($infile)){
        $infile = DEFAULT_INFILE;
        printYellow("--infile was not specified and therefore was set to default '$infile'");
    }

    checkInfileStatus($infile);

    if (!defined($outfile)){
        $outfile = $outdir . '/' . $server . '_server_info_' . strftime "%Y-%m-%d-%H%M%S", gmtime time;
        chomp $outfile;
        $outfile .= '.txt';
        printYellow("--outfile was not specified and therefore was set to default '$outfile'");
    }
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
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

        printBoldRed("input file '$infile' does not exist");

        $errorCtr++;
    }
    else {

        if (!-f $infile){

            printBoldRed("'$infile' is not a regular file");

            $errorCtr++;
        }

        if (!-r $infile){

            printBoldRed("input file '$infile' does not have read permissions");

            $errorCtr++;
        }

        if (!-s $infile){

            printBoldRed("input file '$infile' does not have any content");

            $errorCtr++;
        }
    }

    if ($errorCtr > 0){

        printBoldRed("Encountered issues with input file '$infile'");

        exit(1);
    }
}

sub main {

    if ($insert_provenance){

        open (OUTFILE, ">$outfile") || die ("Could not open '$outfile' in write mode : $!");

        print OUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
        print OUTFILE "## date-created: " . localtime() . "\n";
        print OUTFILE "## server: " . $server . "\n";
        print OUTFILE "## infile: " . File::Spec->rel2abs($infile)  . "\n";

        close OUTFILE;
    }

    my $divider = '-' x 100;

    my @content = read_file($infile);

    for my $line (@content){

        if ($line =~ m/^\#/){
            next;
        }

        if ($line =~ m/^\s*$/){
            next;
        }

        chomp $line;

        print "Will execute command '$line'\n";

        my $cmd1 = "echo '##$divider\n##' >> $outfile";
        execute_cmd($cmd1);

        my $cmd2 = "echo '## Command executed: $line\n##' >> $outfile";
        execute_cmd($cmd2);

        my $cmd3 = "echo '##$divider' >> $outfile";
        execute_cmd($cmd3);

        my $cmd4 = "ssh root\@$server '$line' >> $outfile";
        execute_cmd($cmd4);

        my $cmd5 = "echo '' >> $outfile";
        execute_cmd($cmd5);
    }

    if (-e $outfile){

        if (-s $outfile){

            if (! $no_attach){
                my ($username, $password) = get_credentials();

                my $jira_base_url = get_base_url();

                my $cmd = "curl -D- -u $username:$password -X POST -H 'X-Atlassian-Token: nocheck' -F 'file=\@$outfile' $jira_base_url/rest/api/2/issue/$issue_id/attachments";

                eval {
                    qx($cmd);
                };

                if ($?){
                    die "Encountered some error while attempting to execute '$cmd' : $@ $!";
                }
            }
            else {
                print "Will not attach '$outfile' to JIRA issue '$issue_id'\n";
            }
        }
        else {
            die "server info results file '$outfile' does not have any content";
        }
    }
    else {
        die "server info results file '$outfile' does not exist";
    }

    print "Captured the server info results in '$outfile'\n";
}

sub get_base_url {

    if ($verbose){
        print "Going to read contents of JIRA REST URL file '$jira_rest_url_file'\n";
    }

    my @content = read_file($jira_rest_url_file);

    my $line = $content[0];

    chomp $line;

    $line =~ s/^\s+//;

    $line =~ s/\s+$//;

    return $line;
}

sub get_credentials {

    if ($verbose){
        print "Going to read contents of credential file '$jira_credentials_file'\n";
    }

    my @content = read_file($jira_credentials_file);

    my $line = $content[0];

    chomp $line;

    my ($username, $password) = split(':', $line);

    return ($username, $password);
}

sub execute_cmd {

    my ($cmd) = @_;

    if (!defined($cmd)){
        confess("cmd was not defined");
    }

    if ($verbose){
      print "About to execute '$cmd'\n";
    }

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
