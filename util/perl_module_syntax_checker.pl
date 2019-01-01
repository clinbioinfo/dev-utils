#!/usr/bin/env perl
use strict;
use Cwd;
use Carp;
use Pod::Usage;
use File::Spec;
use File::Path;
use Term::ANSIColor;
use FindBin;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";


use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE   => FALSE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

my $login =  getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

$|=1; ## do not buffer output stream

## Command-line arguments
my (
    $indir,
    $outdir,
    $help,
    $man,
    $verbose,
    );

my $results = GetOptions (
    'help|h'                         => \$help,
    'man|m'                          => \$man,
    'indir=s'                        => \$indir,
    'outdir=s'                       => \$outdir,
    'verbose'                       => \$verbose,
    );

&checkCommandLineArguments();

my $module_file_list = [];

my @dir_list = split(',', $indir);

foreach my $dir (@dir_list){

  if (File::Basename::basename($dir) ne 'lib'){
    $dir .= '/lib';
  }

  if (!-e $dir){
    confess("'$dir' is not a regular directory");
  }

  _load_module_list($dir);
}


my $libraries = join(" -I ", @dir_list);

my $module_file_ctr = 0;
my $error_ctr = 0;
my @error_list;
my @okay_list;
my $okay_ctr = 0;


*STDERR = *STDOUT;

foreach my $module_file (@{$module_file_list}){

  $module_file_ctr++;

  my $cmd = "perl -wc -I $libraries $module_file";

  if ($verbose){
    print "About to execute '$cmd'\n";
  }

  my @results;

  eval {
      @results = qx($cmd);
  };

  if ($?){

    printBoldRed("Encountered error for '$module_file'");

    $error_ctr++;

    push(@error_list, $module_file);
  }
  else {

    chomp @results;

    my $string = $module_file . ' syntax OK';
    my $last_line = $results[$#results-1];
#    my $last_line = pop(@results);
    print "last line '$last_line'\n";

    if ($results[$#results] =~ m/$string\s*$/){

      push(@okay_list, $module_file);

      $okay_ctr++;
    }
    else {

      push(@error_list, $module_file);

      $error_ctr++;

    }
  }
}

print "Processed '$module_file_ctr' module files\n";

if ($error_ctr > 0){

  print "Found the following '$error_ctr' modules with syntax errors:\n";


  foreach my $module_file (@error_list){

    print "\t$module_file\n";
  }
}
else {
  print "All modules had good sytnax\n";
}


printGreen(File::Spec->rel2abs($0) . " execution completed\n");

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

    if (!defined($indir)){

        $indir = DEFAULT_INDIR;

        printYellow("--indir was not specified and therefore was set to default '$indir'");
    }

    $indir = File::Spec->rel2abs($indir);

    if (!defined($outdir)){

        $outdir = DEFAULT_OUTDIR;

        printYellow("--outdir was not specified and therefore was set to default '$outdir'");
    }

    $outdir = File::Spec->rel2abs($outdir);

    if (!-e $outdir){

        mkpath ($outdir) || die "Could not create output directory '$outdir' : $!";

        printYellow("Created output directory '$outdir'");

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

sub _load_module_list {

  my ($dir) = @_;

  my $cmd = "find $dir -name '*.pm'";

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

  my $ctr = 0;

  foreach my $module_file (@results){

    chomp $module_file;

    push(@{$module_file_list}, $module_file);

    $ctr++;
  }

  if ($verbose){
    print "Found '$ctr' modules\n";
  }
}


# sub execute_cmd {

#     my ($cmd, $file) = @_;

#     if (!defined($cmd)){
#         confess("cmd was not defined");
#     }

#     if ($verbose){
#       print "About to execute '$cmd'\n";
#     }

#     my @results;

#     eval {
#         @results = qx($cmd);
#     };

#     if ($?){
#       printBoldRed("Encountered error for '$file'");
#       $error_ctr++;
#       push(@{$error_list}, [$cmd, $file]);
#         # confess("Encountered some error while attempting to execute '$cmd' : $! $@");
#     }

#     chomp @results;

#     return \@results;
# }


__END__

=head1 NAME

 commit_code.pl - Perl script for committing code to Git and then add comment to relevant Jira ticket


=head1 SYNOPSIS

 perl util/commit_code.pl --jira_ticket BDMTNG-552

=head1 OPTIONS

=over 8

=item B<--indir>

  The input directory where all of the source files will be read from.
  Default is two directories above the standard location of this installer
  i.e.: ../util/webInstaller.pl

=item B<--outdir>

  The directory where all output artifacts will be written e.g.: the log file
  if the --logfile option is not specified.
  A default value is assigned /tmp/[username]/webInstaller.pl/[timestamp]/

=item B<--install-dir>

  The directory where the web-based components will be installed.
  Default value assigned is [web-server-dir]/[application-main-dir]

=item B<--web-server-dir>

  The base directory of the Apache2 HTTP Server.
  Default is set to /var/www/

=item B<--application-main-dir>

  The subdirectory that will be created in the [web-server-dir] that will be the target of the install process.
  Default is set to 'bdmdev'

=item B<--css-file-permissions>

  Permission mask for all .css files to be installed.
  Default is set to 644

=item B<--conf-file-permissions>

  Permission mask for all .ini files to be installed.
  Default is set to 644

=item B<--javascript-file-permissions>

  Permission mask for all .js files to be installed.
  Default is set to 644

=item B<--cgi-bin-file-permissions>

  Permission mask for all .cgi files to be installed.
  Default is set to 755

=item B<--lib-file-permissions>

  Permission mask for all .pm files to be installed.
  Default is set to 644

=item B<--default-database-environment>

  This is the value that will be substituted for all instannces of the placeholder variable __DEFAULT_DATABASE_ENVIRONMENT__.
  Default is set to 'Development'

=item B<--apache-web-server-configuration-file>

  This is the Apache2 configuration file that will contain directives pertaining to this installed instance.
  Default is set to /etc/apache2/conf.d/[application-main-dir].conf

=item B<--software-version>

  This is the version of software being installed.
  Default is set to Subversion repository revision number assigned to this script.

=item B<--debug_level>

  The debug level for Log4perl logging.
  Default is set to 3.

=item B<--logfile>

  The Log4perl log file.
  Default is set to [outdir]/webInstaller.pl.log

=item B<--help|-h>

  Print a brief help message and exits.

=item B<--man|-m>

  Prints the manual page and exits.

=item B<--master-registration-file>

  If specified, and does exist- the installed instance of the web application software will be registered in the browsable, master registration file.

=back

=head1 DESCRIPTION

 A script for helping me to inspect and navigate my projects directories.

=head1 CONTACT

 Jaideep Sundaram

 Copyright Jaideep Sundaram

 Can be distributed under GNU General Public License terms

=cut
