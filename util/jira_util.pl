#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Pod::Usage;
use File::Spec;
use File::Path;
use File::Slurp;
use Term::ANSIColor;
use FindBin;

use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_SEND_ZENITY_NOTIFICATION => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_CREDENTIALS_FILE => $ENV{USER} . '.jira/credentials.txt';

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/jira_util.ini";

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_ADMIN_EMAIL_ADDRESS => '';

my $login =  getlogin || getpwuid($<) || $ENV{USER} || "";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Atlassian::Jira::Manager;
# use DevelopmentUtils::Mailer;
use DevelopmentUtils::Ubuntu::Zenity::Manager;

$|=1; ## do not buffer output stream


## Command-line arguments
my (
    $admin_email_address,
    $config_file,
    $credential_file,
    $help, 
    $jira_issue_id,
    $log_level,     
    $logfile, 
    $man,
    $outdir,    
    $send_zenity_notification,
    $test_mode
    $verbose,
    );

my $results = GetOptions (
    'admin_email_address=s'          => \$admin_email_address,
    'config_file=s'                  => \$config_file,
    'credential_file=s'              => \$credential_file,
    'help|h'                         => \$help,
    'jira_issue_id=s'                => \$jira_issue_id,
    'jira_url=s'                     => \$jira_url,
    'log-level|d=s'                  => \$log_level, 
    'logfile=s'                      => \$logfile,   
    'man|m'                          => \$man,
    'outdir=s'                       => \$outdir,    
    'send_zenity_notification=s'     => \$send_zenity_notification,
    'test_mode=s'                    => \$test_mode,
    'verbose'                        => \$verbose,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    logfile   => $logfile, 
    log_level => $log_level
    );

if (!defined($logger)){
    die "Could not instantiate DevelopmentUtils::Logger";
}

my $config_manager = DevelopmentUtils::Config::Manager::getInstance(config_file => $config_file);
if (!defined($config_manager)){
    $logger->logdie("Could not instantiate DevelopmentUtils::Config::Manager");
}


if (!defined($jira_url)){
    
    $jira_url = $config_manager->getJiraURL();
    
    if (!defined($jira_url)){
    
        $jira_url = DEFAULT_JIRA_URL;
    
        $logger->info("jira_url was not defined and therefore was set to default '$jira_url'");
    }
    else {
        $logger->info("jira_url was not defined and therefore was retrieved from the configuration file '$config_file' and set to default '$jira_url'");
    }
}


my $jira_manager = DevelopmentUtils::Atlassian::Jira::Manager::getInstance(
    outdir    => $outdir,
    test_mode => $test_mode,
    credential_file => $credential_file,
    jira_url  => $jira_url
    );

if (!defined($jira_manager)){
    $logger->logdie("Could not instantiate DevelopmentUtils::Atlassian::Jira::Manager");
}

# my $mailer = DevelopmentUtils::Mailer::getInstance(
#     outdir    => $outdir,
#     test_mode => $test_mode,    
#     );

# if (!defined($mailer)){
#     $logger->logdie("Could not instantiate DevelopmentUtils::Mailer");
# }

my $zenity_manager = DevelopmentUtils::Ubuntu::Zenity::Manager::getInstance(
    outdir    => $outdir,
    test_mode => $test_mode
    );

if (!defined($zenity_manager)){
    $logger->logdie("Could not instantiate DevelopmentUtils::Ubuntu::Zenity::Manager");
}

main();

printGreen(File::Spec->rel2abs($0) . " execution completed\n");

print "The log file is '$logfile'\n";

if ($test_mode){
    printYellow("Ran in test mode.  To disable test mode, run with: --test_mode 0");
}

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

    if (!defined($test_mode)){

        $test_mode = DEFAULT_TEST_MODE;
            
        printYellow("--test_mode was not specified and therefore was set to default '$test_mode'");
    }

    if (!defined($send_zenity_notification)){

        $send_zenity_notification = DEFAULT_SEND_ZENITY_NOTIFICATION;
            
        printYellow("--send_zenity_notification was not specified and therefore was set to default '$send_zenity_notification'");
    }

    if (!defined($credential_file)){

        $credential_file = DEFAULT_CREDENTIAL_FILE;
            
        printYellow("--credential_file was not specified and therefore was set to default '$credential_file'");
    }

    checkInfileStatus($credential_file);

    if (!defined($config_file)){

        $config_file = DEFAULT_CONFIG_FILE;
            
        printYellow("--config_file was not specified and therefore was set to '$config_file'");
    }

    &checkInfileStatus($config_file);

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to '$verbose'");
    }

    if (!defined($log_level)){

        $log_level = DEFAULT_LOG_LEVEL;

        printYellow("--log_level was not specified and therefore was set to '$log_level'");
    }

    if (!defined($admin_email_address)){

        $admin_email_address = DEFAULT_ADMIN_EMAIL_ADDRESS;

        printYellow("--admin-email-address was not specified and therefore was set to '$admin_email_address'");
    }

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR;

        printYellow("--outdir was not specified and therefore was set to '$outdir'");
    }

    $outdir = File::Spec->rel2abs($outdir);

    if (!-e $outdir){

        mkpath ($outdir) || die "Could not create output directory '$outdir' : $!";

        printYellow("Created output directory '$outdir'");

    }
    
    if (!defined($logfile)){

    	$logfile = $outdir . '/' . File::Basename::basename($0) . '.log';

    	printYellow("--logfile was not specified and therefore was set to '$logfile'");

    }

    $logfile = File::Spec->rel2abs($logfile);

   if (!defined($jira_issue_id)){

        printBoldRed("--jira_issue_id was not specified");
    }


    my $fatalCtr=0;

    if ($fatalCtr> 0 ){
    	die "Required command-line arguments were not specified\n";
    }
}


sub main {

    my $issue = $jira_manager->getIssue($jira_issue_id);
    if (!defined($issue)){
        $self->{_logger}->logconfess("issue was not defined for issue id '$jira_issue_id'");
    }


    my $id = $issue->get_id;
    my $title = $issue->get_title;
    my $desc = $issue->get_desc;
    my $priority = $issue->get_priority;
    
    my $content = '';

    $content .= "id: $id\n";
    $content .= "title: $title\n";
    $content .= "desc: $desc\n";
    $content .= "priority: $priority\n";
    
    if ($issue->has_labels){        
        
        my $labels = $issue->get_labels;

        if (!defined($labels)){   
                
            $self->{_logger}->logconfess("labels was not defined for issue '$jira_issue_id'");
        }
        
        $content .= "labels: " . join(',', @{$labels}) . "\n";        
    }
    
    if ($issue->has_components){        
    
        my $components = $issue->get_components;

        if (!defined($components)){
        
            $self->{_logger}->logconfess("components was not defined for issue '$jira_issue_id'");
        }
        
        $content .= "components: " . join(',', @{$components}) . "\n";        
    }

    print $content;

    if ($send_zenity_notification){
        
        my $width = $config_manager->get_zenity_info_width();
        if (!defined($width)){
            $logger->logconfess("width was not defined");
        }

        my $height = $config_manager->get_zenity_info_height();
        if (!defined($height)){
            $logger->logconfess("height was not defined");
        }

        $zenity_manager->display_content($content, $width, $height);
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

sub checkOutdirStatus {

    my ($outdir) = @_;

    if (!-e $outdir){
        
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        
        printYellow("Created output directory '$outdir'");
    }
    
    if (!-d $outdir){

        printBoldRed("'$outdir' is not a regular directory\n");
    }
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




__END__

=head1 NAME

 commit_code.pl - Perl script for committing code to Git and then add comment to relevant Jira ticket


=head1 SYNOPSIS

 perl util/commit_code.pl --issue_id BDMTNG-552

=head1 OPTIONS

=over 8

=item B<--outdir>

  The directory where all output artifacts will be written e.g.: the log file
  if the --logfile option is not specified.
  A default value is assigned /tmp/[username]/jira_util.pl/[timestamp]/

=item B<--log_level>

  The Log4perl logging level.  
  Default is set to 4 (INFO).

=item B<--logfile>

  The Log4perl log file.
  Default is set to [outdir]/jira_util.pl.log

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--man|-m>

  Prints the manual page and exits.


=back

=head1 DESCRIPTION


=head1 CONTACT

 Jaideep Sundaram 

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
