
#!/usr/bin/env perl
##------------------------------------------------------------------------------------
##
## Reference: https://gist.github.com/ziadoz/3e8ab7e944d02fe872c3454d17af31a5
##
## See end of this program for more details.
##
##------------------------------------------------------------------------------------
use strict;
use Try::Tiny;
use Term::ANSIColor;
use FindBin;
use File::Copy;
use File::Path;
use File::Compare;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;

use constant TRUE => 1;

use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

my $username = $ENV{USER};

use constant DEFAULT_OUTDIR => '/tmp/' . $username . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

my $steps = [
'rm ~/google-chrome-stable_current_amd64.deb',
'rm ~/selenium-server-standalone-3.0.1.jar',
'rm ~/chromedriver_linux64.zip',
'sudo rm /usr/local/bin/chromedriver',
'sudo rm /usr/local/share/chromedriver',
'sudo rm /usr/local/bin/selenium-server-standalone-3.0.1.jar',
'sudo rm /usr/local/share/selenium-server-standalone-3.0.1.jar',
'sudo apt-get update',
'sudo apt-get install -y openjdk-8-jre-headless xvfb libxi6 libgconf-2-4',
'wget -N https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P .',
'sudo dpkg -i --force-depends ./google-chrome-stable_current_amd64.deb',
'sudo apt-get -f install -y',
'sudo dpkg -i --force-depends ./google-chrome-stable_current_amd64.deb',
'wget -N http://chromedriver.storage.googleapis.com/2.27/chromedriver_linux64.zip -P .',
'unzip ./chromedriver_linux64.zip -d .',
'rm ./chromedriver_linux64.zip',
'sudo mv -f ./chromedriver /usr/local/share/',
'sudo chmod +x /usr/local/share/chromedriver',
'sudo ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver',
'wget -N http://selenium-release.storage.googleapis.com/3.0/selenium-server-standalone-3.0.1.jar -P .',
'sudo mv -f ./selenium-server-standalone-3.0.1.jar /usr/local/share/',
'sudo chmod +x /usr/local/share/selenium-server-standalone-3.0.1.jar',
'sudo ln -s /usr/local/share/selenium-server-standalone-3.0.1.jar /usr/local/bin/selenium-server-standalone-3.0.1.jar'
];


my $help;
my $man;
my $verbose;
my $test_mode;
my $outdir;
my $config_file;
my $log_file;
my $log_level;
my $username;


my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'config_file=s' => \$config_file,
    'username=s'    => \$username
    );

&checkCommandLineArguments();


my $logger = DevelopmentUtils::Logger::getInstance(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

chdir($outdir) || $logger->logdie("Could not change into directory '$outdir' : $!");

printBlue("\nGoing to do this work in directory '$outdir'\n");

run_installation_steps();


if ($verbose){

    printGreen(File::Spec->rel2abs($0) . " execution completed");
}

if ($test_mode){
    printYellow("\nRan in test mode.  Next time execute with '--test_mode 0'");
}

print "The log file is '$log_file'\n";

exit(0);

##--------------------------------------------------------
##
##  END OF MAIN -- SUBROUTINES FOLLOW
##
##--------------------------------------------------------

sub checkCommandLineArguments {
   
   	my $fatalCtr = 0;


    if ($fatalCtr > 0){
    	die "Required command-line arguments were not specified\n";
    }

    if (!defined($username)){

		$username =  getlogin || getpwuid($<) || "sundaramj";

        printYellow("--username was not specified and therefore was set to default '$username'");        
    }


    if (!defined($verbose)){

        $verbose = DEFAULT_VERBOSE;
        
        printYellow("--verbose was not specified and therefore was set to default '$verbose'");
        
    }


    if (!defined($config_file)){
        
        $config_file = DEFAULT_CONFIG_FILE;
        
        printYellow("--config_file was not specified and therefore was set to default '$config_file'");        
    }


    if (!defined($log_level)){
        
        $log_level = DEFAULT_LOG_LEVEL;
        
        printYellow("--log_level was not specified and therefore was set to default '$log_level'");        
    }

 
    if (!defined($test_mode)){

        $test_mode = DEFAULT_TEST_MODE;
        
        printYellow("--test_mode was not specified and therefore was set to default '$test_mode'");        
    }

    if (!defined($outdir)){
        
        $outdir = DEFAULT_OUTDIR;
        
        printYellow("--outdir was not specified and therefore was set to default '$outdir'");        
    }

    if (!-e $outdir){
        mkpath($outdir) || die "Could not create output directory '$outdir' : $!";
        print "Created output directory '$outdir'\n";
    }

    if (!defined($log_file)){

        $log_file = $outdir . '/' . File::Basename::basename($0) . '.log';
        
        printYellow("--log_file was not specified and therefore was set to default '$log_file'");        
    }

}


sub run_installation_steps {

    foreach my $step (@{$steps}){

        if ($step =~ m|^rm (\S+)|){
            
            my $asset = $1;
            
            if (!-e $asset){

                if (! $test_mode){        
                 
                    $logger->info("asset '$asset' does not exist so will not attempt to delete it");
                
                    next;
                }
            }
        }
        elsif ($step =~ m|^sudo rm (\S+)|){
            
            my $asset = $1;
            
            if (!-e $asset){
            
                if (! $test_mode){        
        
                    $logger->info("asset '$asset' does not exist so will not attempt to delete it");
                
                    next;
                }
            }
        }
        elsif ($step =~ m|^sudo ln \-s (\S+) \S+|){
            
            my $source = $1;
                        
            my $error_ctr = 0;

            if (!-e $source){
            
                if (! $test_mode){        
        
                    $logger->error("In step '$step': source '$source' does not exist");
                
                    $error_ctr++;
                }
            }

            if ($error_ctr > 0){
                $logger->logconfess("Something went wrong at (or prior to) step '$step'");
            }
        }
        elsif ($step =~ m|^sudo mv \-f (\S+) (\S+)|){
            
            my $source = $1;
            
            my $target = $2;
            
            my $error_ctr = 0;

            if (!-e $source){
        
                if (! $test_mode){            
                    $logger->error("In step '$step': source '$source' does not exist");
                
                    $error_ctr++;
                }
            }

            if (!-e $target){
            
                if (! $test_mode){        
                    $logger->error("In step '$step': target '$target' does not exist");
                
                    $error_ctr++;
                }
            }

            if ($error_ctr > 0){
                $logger->logconfess("Something went wrong at (or prior to) step '$step'");
            }
        }
        elsif ($step =~ m|^sudo chmod \-x (\S+)|){
            
            my $asset = $1;
                    
            if (!-e $asset){
            
                if (! $test_mode){        
                    $logger->logdie("In step '$step': asset '$asset' does not exist");
            
                }        
            }
        }

        execute_cmd($step);
        # print "Will execute '$step'\n";
    }
}


sub execute_cmd {

    my ($cmd) = @_;

    $logger->info("About to execute '$cmd'");

    if ($test_mode){
        printYellow("Running in test mode - would have executed: '$cmd'");
    }
    else {

        printBlue("About to execute '$cmd'");
        
        try {
            qx($cmd);

        } catch {
        
            $logger->logconfess("Encountered some error while attempting to execute '$cmd' : $_");
        }
    }
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
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

sub printBlue {

    my ($msg) = @_;
    print color 'blue';
    print $msg . "\n";
    print color 'reset';
}


__END__

