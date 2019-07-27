#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Data::Dumper;
use Pod::Usage;
use File::Copy;
use File::Spec;
use File::Slurp;
use File::Path;
use File::Basename;
use Term::ANSIColor;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_NO_CREATE_COMMIT_COMMENT_FILE => FALSE;

$|=1; ## do not buffer output stream

## Command-line arguments
my (
    $help,
    $man,
    $verbose,
    $no_create_commit_comment_file
    );

my $results = GetOptions (
    'help|h'     => \$help,
    'man|m'      => \$man,
    'verbose'    => \$verbose,
    'no_create_commit_comment_file' => \$no_create_commit_comment_file,
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

    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;

        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
    }

    my $fatalCtr=0;

    if ($fatalCtr> 0 ){
        die "Required command-line arguments were not specified\n";
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

my $jira_url;
my $branch_name;
my $commit_checksum;
my $git_project;

sub main {

  my $url = get_repos_url();

  # print "url '$url'\n";

  get_current_branch_name();

  my $commit_message = get_commit_message();

  if (defined($jira_url)){

    printYellow("\nPlease add this to '$jira_url'\n");

    my $full_url =  $url . '/commits/' . $commit_checksum;

    print "Committed [this|$full_url] to git repo for $git_project ($branch_name branch) with the following commit comment:\n";

    print "{quote}\n" . join("\n", @{$commit_message}) . "\n{quote}\n\n";

    if (! $no_create_commit_comment_file){

        my $outfile = "./commit_comment_file.txt";

        if (-e $outfile){

            _backup_file($outfile);
        }

        open (OUTFILE, ">$outfile") || die ("Could not open '$outfile' in write mode : $!");

        print OUTFILE "Committed [this|$full_url] to git repo for $git_project ($branch_name branch) with the following commit comment:\n";

        print OUTFILE join("\n", @{$commit_message}) . "\n\n";

        close OUTFILE;

        print ("Wrote commit comment file '$outfile'\n");
    }
  }
}

sub _backup_file {

    my ($file) = @_;

    my $bakfile = $file . '.bak';

    move($file, $bakfile) || die ("Could not move '$file' to '$bakfile' : $!");

    print("Backed-up '$file' to '$bakfile'\n");
}

sub get_current_branch_name {

  my $cmd = "git --no-pager branch | grep \\* | cut -d ' ' -f2";

  my $results = execute_cmd($cmd);

  $branch_name = $results->[0];
}

sub get_commit_message {

  my $cmd = "git --no-pager log -n 1";

  my $results = execute_cmd($cmd);

  my @commit_message;

  my $line_ctr = 0;

  for my $line (@{$results}){

    $line_ctr++;

    chomp $line;

    if ($line_ctr == 1){
      if ($line =~ m/^commit\s+(\S+)\s+\(HEAD\s+->\s+(\S+),{0,1}/){

        $commit_checksum = $1;

        next;
      }
      elsif ($line =~ m/^commit\s+(\S+)/){

        $commit_checksum = $1;

        next;
      }
      else {
        confess "Could not parse '$line'";
      }
    }

    if ($line =~ m/^Author:\s+/){

      next;
    }
    elsif ($line =~ m/^Date:\s+/){

      next;
    }
    elsif ($line =~ m/^\s*$/){

      next;
    }

    $line =~ s/^\s+//; ## Remove leading white space

    if ($line =~ m/^Reference\s*:\s*(\S+)/){

      $jira_url = $1;

      next;
    }

    push(@commit_message, $line);
  }

  return \@commit_message;
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

sub get_repos_url {

  my $git_file = cwd() . '/.git/config';
  if (!-e $git_file){
    die "git file '$git_file' does not exist";
  }

  my @contents = read_file($git_file);
  for my $line (@contents){
    chomp $line;
    if ($line =~ /^\s+url\s*=\s*(.+)\s*$/){
      return transform_url($1);
    }
  }

  die "Did not find the url in git file '$git_file'";

}

sub transform_url {
  my ($ssh_url) = @_;
  ## This : ssh://git@code.ad.organization.com:7999/rep/project.git
  ## has to be transformed into this: https://code.ad.organization.com/projects/REP/repos/project

  if ($ssh_url =~ m|^ssh://git\@|){

    $ssh_url =~ s|^ssh://git\@|https://|;

    if ($ssh_url =~ m|:\d+|){

      $ssh_url =~ s|:\d+|/projects|;

      my $pre = File::Basename::dirname($ssh_url);

      my $post = File::Basename::basename($ssh_url);

      if ($post =~ m/^(\S+)\.git$/){

        $post = $1;

        $git_project = $post;

        my $final = $pre . '/repos/' . $post;

        return $final;
      }
      else {
        confess "Unexpected base '$post'";
      }
    }
    else {
      confess "Unexpected url '$ssh_url'";
    }
  }
  else {
    confess "Unexpected ssh url '$ssh_url'";
  }

}
