#!/usr/bin/env perl

use strict;
use File::Slurp;
use Data::Dumper;
use Term::ANSIColor;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use FindBin;

use lib "$FindBin::Bin/../lib";

use DevelopmentUtils::Logger;


use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_LOG_LEVEL => 4;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/commit_code.ini";

my (
    $help,
    $man,
    $outdir,
    $verbose,
    $test_mode,
    $log_file,
    $log_level,
    $config_file,
    $indir,
    $infile,
    );

my $results = GetOptions (
    'help|h'        => \$help,
    'man|m'         => \$man,
    'outdir=s'      => \$outdir,
    'verbose=s'     => \$verbose,
    'test_mode=s'   => \$test_mode,
    'log_level=s'   => \$log_level,
    'log_file=s'    => \$log_file,
    'indir=s'       => \$indir,
    'infile=s'      => \$infile,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

&main();

if ($verbose){
    print color 'green';
    print File::Spec->rel2abs($0) . " execution completed\n";
    print color 'reset';
}

print "The log file is '$log_file'\n";
exit(0);

##----------------------------------------------------------------------
##
##   END OF MAIN -- SUBROUTINES FOLLOW
##
##----------------------------------------------------------------------

sub checkCommandLineArguments {

    if ($man){
        &pod2usage({-exitval => 1, -verbose => 2, -output => \*STDOUT});
    }

    if ($help){
        &pod2usage({-exitval => 1, -verbose => 1, -output => \*STDOUT});
    }

    my $fatalCtr = 0;

    if ((!defined($indir)) && (!(defined($infile)))){

        printBoldRed("You must specified either --indir or --infile was not specified");

        $fatalCtr++;
    }

    if ($fatalCtr> 0 ){
        printBoldRed("Required command-line arguments were not specified");
        exit(1);
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

sub main($) {

    my $file_list;

    if (defined($infile)){
        &checkInfileStatus($infile);
        $file_list = [$infile];
    }

    if (defined($indir)){

        my $cmd = "find $indir -name '*.pm'";

        print "About to execute '$cmd'\n";

        $logger->info("About to execute '$cmd'");

        my @list  = qx($cmd);

        chomp @list;

        $file_list = \@list;
    }

    for my $file (@{$file_list}){

        &process_file($file);
    }

}

sub process_file($) {

    my ($file) = @_;

    my $lookup = &parse_module($file);

    &create_test_file($lookup, $file);
}

sub create_test_file($$){

    my ($lookup, $file) = @_;

    # print Dumper $lookup;

    my $test_outdir = $outdir . '/t';

    my $package = $lookup->{'package'};

    my $outfile = $package;

    $outfile =~ s/::/_/g;

    my $test_file = $test_outdir . '/' . 'test_' . $outfile . '.t';

    if (!-e $test_outdir){
        mkpath($test_outdir) || $logger->logconfess("Could not create directory '$test_outdir' :$!");
        $logger->info("Created directory '$test_outdir'");
    }
    else {
        $logger->info("Test directory '$test_outdir' already exists");
    }


    open (OUTFILE, ">$test_file") || $logger->logconfess("Could not open output file '$test_file' in write mode : $!");

    print OUTFILE '#!/usr/bin/env perl' . "\n";
    print OUTFILE '## Test for ' . $file . "\n";
    print OUTFILE 'use strict;' . "\n";

    my $add_username = FALSE;
    my $add_login = FALSE;

    if (exists $lookup->{constant_list}){

        ## Add core Perl modules needed by declared constants

        for my $constant (@{$lookup->{constant_list}}){

            if ($constant =~ m/File::Basename/){
                print OUTFILE 'use File::Basename;' . "\n";
            }
            if ($constant =~ m/hostname/){
                print OUTFILE 'use Sys::Hostname;' . "\n";
            }
            if ($constant =~ m/cwd/){
                print OUTFILE 'use Cwd;' . "\n";
            }
            if ($constant =~ m/\$username/){
                $add_username = TRUE;
            }
            if ($constant =~ m/\$login/){
                $add_login = TRUE;
            }

        }
    }


    my $test_count = 3;
    if (exists $lookup->{data_member_list}){
        $test_count = scalar(@{$lookup->{data_member_list}}) + 3;
    }

    print OUTFILE 'use FindBin;' . "\n\n";
    print OUTFILE 'use Test::More tests => ' . $test_count . ';' . "\n";

    print OUTFILE 'use lib "$FindBin::Bin/../lib/";' . "\n\n";
    print OUTFILE '' . "\n";

    if ($add_login){
        print OUTFILE 'my $login = \'sundaram\';' . "\n";
    }

    if ($add_username){
        print OUTFILE 'my $username = \'sundaram\';' . "\n";
    }

    if (exists $lookup->{constant_list}){
        print OUTFILE '## constants declared in module ' . $package . "\n";
        print OUTFILE join("\n", @{$lookup->{constant_list}}) . "\n";
        print OUTFILE '' . "\n";
    }

    print OUTFILE 'require_ok(\'' . $package . '\');' . "\n\n";
    print OUTFILE 'use ' . $package . ';' . "\n\n";
    print OUTFILE 'can_ok(\'' . $package . '\', qw(' . join(' ', @{$lookup->{method_list}}) . '));' . "\n";
    print OUTFILE '' . "\n\n";



    if ($package =~ m/Parser/){
        if ($package =~ m/Tab/){
            &add_example_tab_file();

        }
        elsif ($package =~ m/CSV/){
            &add_example_csv_file();
        }
    }

    if ($package =~ m/Writer/){
        if ($package =~ m/Tab/){
            &add_example_tab_file();

        }
        elsif ($package =~ m/CSV/){
            &add_example_csv_file();
        }
    }

    ## Create some variables for testing the data members
    my $declared_variables_lookup = {};

    for my $data_member (@{$lookup->{data_member_list}}){

        my $name = $data_member->{name};
        print OUTFILE 'my $' . $name . ' = ';

        if (! exists $data_member->{default}){

            my $type = $data_member->{type};


            if ($type eq 'Bool'){
                print OUTFILE 'TRUE;';
                $declared_variables_lookup->{$name} = TRUE;
            }
            elsif ($type eq 'Str'){
                print OUTFILE '\'SOME ' . uc($name) . '\';';
                $declared_variables_lookup->{$name} = 'SOME ' . uc($name);
            }
            elsif ($type eq 'ArrayRef'){
                my @array = qw(a b c d);
                print OUTFILE "['a', 'b', 'c', 'd'];";
                $declared_variables_lookup->{$name} = \@array;
            }
            elsif ($type eq 'HashRef'){
                my @array = qw(a b c d);
                my %hash = map {$_ => 1} @array;
                print OUTFILE "{'a' => 1, 'b' => 1, 'c' => 1, 'd' => 1};";
                $declared_variables_lookup->{$name} = \%hash;
            }
            else {
                print OUTFILE "'',";
            }
        }
        else {
            my $default_value = $data_member->{default};
            print OUTFILE $default_value . ';';
        }

        print OUTFILE "\n";
    }

    print OUTFILE "\n\n\n";

    my $instantiation_string;

    if (exists $lookup->{method_lookup}->{getInstance}){
        $instantiation_string = 'my $instance = ' . $package . '::getInstance(';
        print OUTFILE $instantiation_string . "\n";
    }
    else {
        $instantiation_string = 'my $instance = new ' . $package . '(';
        print OUTFILE $instantiation_string . "\n";
    }

    my $len = length($instantiation_string);
    my $leading_space = ' ' x $len;
    my $leading_space = "\t";


    for my $data_member (@{$lookup->{data_member_list}}){

        if (! exists $data_member->{default}){

            my $name = $data_member->{name};
            my $type = $data_member->{type};

            print OUTFILE $leading_space . $name . ' => ';
            if ($type eq 'Bool'){
                print OUTFILE 'TRUE', . "\n";
            }
            else {
                if (exists $declared_variables_lookup->{$name}){
                    my $value = $declared_variables_lookup->{$name};
                    print OUTFILE '\'' . $value . '\',' . "\n";

                }
                else {
                    print OUTFILE "''," . "\n";
                }
            }
        }
    }
    print OUTFILE $leading_space . ');' . "\n\n";


    print OUTFILE 'ok( defined($instance) && ref $instance eq \'' . $package . '\',     \'instantiantion works\' );' . "\n";


    ## Write the data member value checks here
    for my $data_member (@{$lookup->{data_member_list}}){

        my $name = $data_member->{name};

        my $type = $data_member->{type};

        my $getter = $data_member->{getter};

        if (!exists $data_member->{default}){
            if (exists $declared_variables_lookup->{$name}){
                my $value = $declared_variables_lookup->{$name};
                print OUTFILE 'is($instance->' . $getter . "(), '" . $value . "' , 'testing " . $getter . "()');" . "\n";
            }
            else {
                $logger->logconfess("name '$name' does not exist in the declared_variables_lookup");
            }
        }
        else {
            my $value = $data_member->{default};
            print OUTFILE 'is($instance->' . $getter . "(), " . $value . " , 'testing " . $getter . "()');" . "\n";
        }
    }

    print OUTFILE "\n\n";

    close OUTFILE;

    $logger->info("Wrote '$test_file' for package '$package'");

    print "Wrote '$test_file' for package '$package'\n";

}


sub add_example_tab_file(){

    print OUTFILE 'my $example_tab_file = "/tmp/example_tab_file.txt";' . "\n";
    print OUTFILE 'if (!-e $example_tab_file){' . "\n";
    print OUTFILE '    open(OUTFILE, ">$example_tab_file") || die "Could not open example tab-delimted file \'$example_tab_file\' : $!";' . "\n";
    print OUTFILE '    print OUTFILE "A\tB\tC\tD\nE\tF\tG\tH\n";' . "\n";
    print OUTFILE '    close OUTFILE;' . "\n";
    print OUTFILE '}' . "\n";
}


sub add_example_csv_file(){

    print OUTFILE 'my $example_csv_file = "/tmp/example_csv_file.csv";' . "\n";
    print OUTFILE 'if (!-e $example_csv_file){' . "\n";
    print OUTFILE '    open(OUTFILE, ">$example_csv_file") || die "Could not open example comma-separated file \'$example_csv_file\' : $!";' . "\n";
    print OUTFILE '    print OUTFILE "A,B,C,D\nE,F,G,H\n";' . "\n";
    print OUTFILE '    close OUTFILE;' . "\n";
    print OUTFILE '}' . "\n";
}

sub parse_module($) {

    my ($file) = @_;

    print "Processing file '$file'\n";

    $logger->info("About to parse '$file'");

    my @lines = read_file($file);

    chomp @lines;

    my $found_data_member = FALSE;

    my $lookup = {};

    my $current_lookup;

    my $line_ctr = 0;

    for my $line (@lines){

        $line_ctr++;

        if ($line =~ m/^package (\S+);/){
            $lookup->{package} = $1;
            next;
        }

        if ($line =~ m/^has '(\S+)' \=\>/){

            if (defined($current_lookup)){
                push(@{$lookup->{data_member_list}}, $current_lookup);
            }

            $current_lookup = undef;
            $current_lookup->{name} = $1;
            $found_data_member = TRUE;

            next;
        }

        if ($line =~ m/^use constant /){
            push(@{$lookup->{constant_list}}, $line);
        }

        if ($line =~ m/^\s+\);\s*$/){

            if ($found_data_member){

                if (defined($current_lookup)){
                    push(@{$lookup->{data_member_list}}, $current_lookup);
                }

                $current_lookup = undef;

                $found_data_member = FALSE;

                next;
            }
        }
        if ($line =~ m/^\s+isa\s+\=\>\s+'(\S+)',{0,1}\s*$/){

            if ($found_data_member){
                $current_lookup->{type} = $1;
            }
            else {
                die "$line";
            }
            next;
        }

        if ($line =~ m/^\s+writer\s+\=\>\s+'(\S+)',{0,1}\s*$/){

            if ($found_data_member){
                $current_lookup->{setter} = $1;
                push(@{$lookup->{method_list}}, $1);
            }
            else {
                die "$line";
            }

            next;
        }

        if ($line =~ m/^\s+reader\s+\=\>\s+'(\S+)',{0,1}\s*$/){

            if ($found_data_member){
                $current_lookup->{getter} = $1;
                push(@{$lookup->{method_list}}, $1);
            }
            else {
                die "$line";
            }

            next;
        }

        if ($line =~ m/^\s+required\s+\=\>\s+'(\S+)',{0,1}\s*$/){
            if ($found_data_member){
                $current_lookup->{required} = $1;
            }
            else {
                die "$line";
            }

            next;
        }

        if ($line =~ m/^\s+default\s+\=\>\s+(\S+),{0,1}\s*$/){
            if ($found_data_member){
                $current_lookup->{default} = $1;
            }
            else {
                die "$line";
            }

            next;
        }

        if ($line =~ m/^\s*$/){
            next;
        }

        if ($line =~ m/^\#+/){
            next;
        }

        if ($line =~ m/^sub (\S+)\s*{\s*$/){
            if (defined $current_lookup){
                push(@{$lookup->{data_member_list}}, $current_lookup);
            }
            $current_lookup = undef;
            push(@{$lookup->{method_list}}, $1);
            next;
        }
    }

    if (defined($current_lookup)){
        push(@{$lookup->{data_member_list}}, $current_lookup);
    }

    my %hash = map{$_ => TRUE} @{$lookup->{method_list}};

    $lookup->{method_lookup} = \%hash;

    print "Processed '$line_ctr' lines\n";

    $logger->info("Processed '$line_ctr' lines");

    return $lookup;
}