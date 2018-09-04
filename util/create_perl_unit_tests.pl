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
    $author_name,
    $author_email
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
    'author_name=s'  => \$author_name,
    'author_email=s' => \$author_email,
    );

&checkCommandLineArguments();

my $logger = new DevelopmentUtils::Logger(
    log_level => $log_level,
    log_file  => $log_file
    );

if (!defined($logger)){
    $logger->logconfess("Could not instantiate DevelopmentUtils::Logger");
}

my $file_to_module_lookup = {};
my $package_to_file_lookup = {};

my $logger_module_found = FALSE;
my $logger_module_package_name;

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

    if (!defined($author_email)){

        printBoldRed("--author_email was not specified");

        $fatalCtr++;
    }

    if (!defined($author_name)){

        printBoldRed("--author_name was not specified");

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

    my $file_count = scalar(@{$file_list});

    $logger->info("Going to parse '$file_count' module files");

    for my $file (@{$file_list}){

        my $lookup = &parse_module($file);

        $file_to_module_lookup->{$file} = $lookup;

        $package_to_file_lookup->{$lookup->{package}} = $file;
    }

    $logger->info("Going to create '$file_count' unit test files");

    for my $file (sort keys %{$file_to_module_lookup}){

        my $lookup = $file_to_module_lookup->{$file};

        &transfer_all_base_class_attributes($lookup);

        &create_test_file($lookup, $file);
    }

    print "\nWrote all unit-test files to $outdir/t/\n";

    $logger->info("Wrote all unit-test files to $outdir/t/");
}

sub transfer_all_base_class_attributes($){

    my ($lookup) = @_;

    my $package = $lookup->{package};

    if (exists $lookup->{extends_list}){

        for my $parent_package (@{$lookup->{extends_list}}){

            $logger->info("package '$package' extends '$parent_package'");

            my $file = $package_to_file_lookup->{$parent_package};

            my $parent_lookup = $file_to_module_lookup->{$file};

            &transfer_all_base_class_attributes($parent_lookup);

            if (exists $parent_lookup->{data_member_name_to_lookup}){
                for my $data_member_name (keys %{$parent_lookup->{data_member_name_to_lookup}}){
                    if (!exists $lookup->{data_member_name_to_lookup}->{$data_member_name}){
                        my $data_member_lookup = $parent_lookup->{data_member_name_to_lookup}->{$data_member_name};
                        push(@{$lookup->{data_member_list}}, $data_member_lookup);
                        $lookup->{data_member_name_to_lookup}->{$data_member_name} = $data_member_lookup;
                    }
                }
            }

            if (exists $parent_lookup->{constant_list}){
                for my $constant (@{$parent_lookup->{constant_list}}){
                    if (!exists $lookup->{constant_lookup}->{$constant}){
                        push(@{$lookup->{constant_list}}, $constant);
                    }
                }
            }

            if (exists $parent_lookup->{constant_lookup}){
                for my $constant (keys %{$parent_lookup->{constant_lookup}}){
                    my $constant_value = $parent_lookup->{constant_lookup}->{$constant};
                    $lookup->{constant_lookup}->{$constant} = $constant_value;
                }
            }

            if (exists $parent_lookup->{method_list}){
                for my $method (@{$parent_lookup->{method_list}}){
                    if (!exists $lookup->{method_lookup}->{$method}){
                        push(@{$lookup->{method_list}}, $method);
                    }
                }
            }

            if (exists $parent_lookup->{method_lookup}){
                for my $method (keys %{$parent_lookup->{method_lookup}}){

                    $lookup->{method_lookup}->{$method}++;
                }
            }
        }
    }
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
    print OUTFILE "\n";
    print OUTFILE '## Test for package '. $package . "\n";
    print OUTFILE '## defined in file ' . $file . "\n";

    if (exists $lookup->{extends_list}){

        my $extends_count = scalar(@{$lookup->{extends_list}});
        if ($extends_count == 1){
            print OUTFILE '## Extends the following ' . $extends_count . ' package:' . "\n";
        }
        else {
            print OUTFILE '## Extends the following ' . $extends_count . ' packages:' . "\n";
        }
        for my $extends_package (@{$lookup->{extends_list}}){
            print OUTFILE '##    ' . $extends_package . "\n";
        }
    }


    print OUTFILE 'use strict;' . "\n";
    print OUTFILE 'use Pod::Usage;' . "\n";

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


    if ($logger_module_found){
        if (defined($logger_module_package_name)){
            print OUTFILE 'use ' . $logger_module_package_name . ';' . "\n\n";
            print OUTFILE 'my $logfile = "/tmp/sample.log";' . "\n";
            print OUTFILE 'my $logger = ' . $logger_module_package_name . '::getInstance(log_level => 4, log_file => $logfile);' . "\n";
        }
        else {
            $logger->logconfess("logger_module_package_name was not defined while processing package '$package' file '$file'");
        }
        print OUTFILE "\n\n";
    }

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


    if (exists $lookup->{data_member_name_to_lookup}){
        for my $name (keys %{$lookup->{data_member_name_to_lookup}}){

            if ($name =~ m/outfile/){
                &add_example_outfile($package);
            }
            elsif ($name =~ m/outdir/){
                &add_example_outdir();
            }
            elsif ($name =~ m/file/){
                &add_example_outfile($package);
            }
            elsif ($name =~ m/dir/){
                &add_example_outdir();
            }
        }
    }


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

    print OUTFILE "\n" . '## Declare variables to support testing' . "\n\n";

    for my $data_member (@{$lookup->{data_member_list}}){

        my $name = $data_member->{name};


        if (exists $data_member->{default}){

            my $default_value = $data_member->{default};
            $logger->info("data member '$name' has default '$default_value' so will not create a variable");
        }
        else {

            my $type = $data_member->{type};

            print OUTFILE 'my $' . $name . ' = ';

            if ($type eq 'Bool'){
                print OUTFILE 'TRUE;';
                $declared_variables_lookup->{$name} = TRUE;
            }
            elsif ($type eq 'Str'){
                if ($name =~ /file/){
                    print OUTFILE '$example_outfile;';
                    $declared_variables_lookup->{$name} = '$example_outfile';
                }
                elsif ($name =~ /dir/){
                    print OUTFILE '$example_outdir;';
                    $declared_variables_lookup->{$name} = '$example_outdir';
                }
                else {
                    print OUTFILE '\'SOME ' . uc($name) . '\';';
                    $declared_variables_lookup->{$name} = 'SOME ' . uc($name);
                }
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

            print OUTFILE "\n";
        }
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

        my $name = $data_member->{name};

        if (exists $data_member->{default}){
            my $constant_name = $data_member->{default};
            my $constant_value = $lookup->{constant_lookup}->{$constant_name};
            if ($constant_value !~ m/time\(\)/){
                ## Do nothing
                $logger->info("member name '$name' constant name '$name' constant value '$constant_value'");
            }
            else {
                my $value = $data_member->{default};
                $logger->info("member name '$name' constant name '$name' constant value '$constant_value'");
                print OUTFILE $leading_space . $name . ' => ' . $constant_name . ',' . "\n";
            }
        }
        else {

            my $type = $data_member->{type};

            if ($type eq 'Bool'){

                print OUTFILE $leading_space . $name . ' => ';
                print OUTFILE 'TRUE', . "\n";
            }
            else {
                if (exists $declared_variables_lookup->{$name}){

                    my $value = $declared_variables_lookup->{$name};

                    print OUTFILE $leading_space . $name . ' => ';
                    if (($name =~ m/file/) || ($name =~ m/dir/)){
                        print OUTFILE $value . ',' . "\n";
                    }
                    else {
                        print OUTFILE '\'' . $value . '\',' . "\n";
                    }
                }
                else {
                    print OUTFILE $leading_space . $name . ' => ';
                    print OUTFILE "''," . "\n";
                }
            }
        }
    }
    print OUTFILE $leading_space . ');' . "\n\n";


    print OUTFILE 'ok( defined($instance) && ref $instance eq \'' . $package . '\', \'instantiation works\' );' . "\n";


    ## Write the data member value checks here
    for my $data_member (@{$lookup->{data_member_list}}){

        my $name = $data_member->{name};

        my $type = $data_member->{type};

        my $getter = $data_member->{getter};

        if (!exists $data_member->{default}){
            if (exists $declared_variables_lookup->{$name}){
                my $value = $declared_variables_lookup->{$name};
                if (($name =~ m/file/) || ($name =~ m/dir/)){
                    print OUTFILE 'is($instance->' . $getter . "(), " . $value . " , 'testing " . $getter . "()');" . "\n";
                }
                else{
                    print OUTFILE 'is($instance->' . $getter . "(), '" . $value . "' , 'testing " . $getter . "()');" . "\n";
                }
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

    &add_pod_usage($test_file, $package);

    close OUTFILE;

    $logger->info("Wrote '$test_file' for package '$package'");

    print "Wrote '$test_file' for package '$package'\n";

}


sub add_pod_usage($$){

    my ($test_file, $package) = @_;

    my $basename = File::Basename::basename($test_file);

    print OUTFILE '__END__' . "\n\n";

    print OUTFILE '=head1 NAME' . "\n\n";

    print OUTFILE $basename . ' - Unit tests for ' . $package . "\n\n";


    print OUTFILE '=head1 SYNOPSIS' . "\n\n";

    print OUTFILE 'prove t/' . $basename . "\n\n";
    print OUTFILE 'prove -v t/' . $basename . "\n\n";

    print OUTFILE '=head1 DESCRIPTION' . "\n\n";

    print OUTFILE 'This script should be used to execute unit tests against package' . "\n";
    print OUTFILE $package . '.' . "\n\n";

    print OUTFILE '=head1 CONTACT' . "\n\n";

    print OUTFILE $author_name . "\n\n";

    print OUTFILE $author_email . "\n\n";

    print OUTFILE 'Copyright Jaideep Sundaram 2018' . "\n\n";

    print OUTFILE 'Can be distributed under GNU General Public License terms' . "\n\n";

    print OUTFILE '=cut' . "\n\n";
}

sub add_example_outfile($){

    my ($package) = @_;

    print OUTFILE "\n";
    print OUTFILE 'my $example_outfile = "/tmp/example_outfile.txt";' . "\n";
    print OUTFILE 'open(OUTFILE, ">>$example_outfile") || die "Could not open example output file \'$example_outfile\' : $!";' . "\n";
    print OUTFILE 'print OUTFILE "Random example output file to test package \'' . $package . '\'\n";' . "\n";
    print OUTFILE 'close OUTFILE;' . "\n";
}

sub add_example_outdir(){

    print OUTFILE "\n";
    print OUTFILE 'my $example_outdir = "/tmp/example_outdir";' . "\n";
    print OUTFILE 'use File::Path;' . "\n";
    print OUTFILE 'if (!-e $example_outdir){' . "\n";
    print OUTFILE '    mkpath($example_outdir) || die "Could not create directory \'$example_outdir\'";' . "\n";
    print OUTFILE '}' . "\n";
}

sub add_example_tab_file(){

    print OUTFILE "\n";
    print OUTFILE 'my $example_tab_file = "/tmp/example_tab_file.txt";' . "\n";
    print OUTFILE 'open (OUTFILE, ">>$example_tab_file") || die "Could not open example tab-delimted file \'$example_tab_file\' : $!";' . "\n";
    print OUTFILE 'print OUTFILE "A\tB\tC\tD\nE\tF\tG\tH\n";' . "\n";
    print OUTFILE 'close OUTFILE;' . "\n";
}


sub add_example_csv_file(){

    print OUTFILE "\n";
    print OUTFILE 'my $example_csv_file = "/tmp/example_csv_file.csv";' . "\n";
    print OUTFILE 'open(OUTFILE, ">>$example_csv_file") || die "Could not open example comma-separated file \'$example_csv_file\' : $!";' . "\n";
    print OUTFILE 'print OUTFILE "A,B,C,D\nE,F,G,H\n";' . "\n";
    print OUTFILE 'close OUTFILE;' . "\n";
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

            my $package = $1;

            if ($package =~ m/Logger/){
                $logger_module_found = TRUE;
                $logger_module_package_name = $package;
            }

            $lookup->{package} = $package;
            next;
        }

        if ($line =~ m/^extends '(\S+)';/){

            push(@{$lookup->{extends_list}}, $1);
            next;
        }

        if ($line =~ m/^extends "(\S+)";/){

            push(@{$lookup->{extends_list}}, $1);
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

        if ($line =~ m/^use constant (\S+)\s*=>\s*(.+);/){
            my $name = $1;
            my $val = $2;
            push(@{$lookup->{constant_list}}, $line);
            $lookup->{constant_lookup}->{$name} = $val;
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

        if ($line =~ m/^\s+default\s+\=\>\s+(.+),{0,1}\s*$/){
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


    for my $data_member_lookup (@{$lookup->{data_member_list}}){
        my $name = $data_member_lookup->{name};
        $lookup->{data_member_name_to_lookup}->{$name} = $data_member_lookup;
    }

    my %hash = map{$_ => TRUE} @{$lookup->{method_list}};

    $lookup->{method_lookup} = \%hash;

    print "Processed '$line_ctr' lines\n";

    $logger->info("Processed '$line_ctr' lines");

    return $lookup;
}