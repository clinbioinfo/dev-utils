package DevelopmentUtils::Perl::Module::File::Writer;

use Moose;
use Cwd;
use String::CamelCase qw(decamelize);
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;


use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Perl::Module::File::Writer(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Perl::Module::File::Writer";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);


    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}


sub _initLogger {

    my $self = shift;

    my $self->{_logger} = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($self->{_logger})){
        confess "logger was not defined";
    }

    $self->{_logger} = $self->{_logger};
}

sub _initConfigManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
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


sub createAPI {

    my $self = shift;
    
    if ($self->getVerbose()){
        print "About to create the API in directory '$outdir'\n";
    }


    my $moduleLookup = {};
    my $moduleCtr = 0;
    my $ignoredModuleCtr = 0;
    my $ignoredModuleLookup = {};



    if ($self->getVerbose()){
        $self->{_logger}->info("Found the following '$moduleCtr' modules:");
        foreach my $name (sort keys %{$moduleLookup}){
            $self->{_logger}->info($name);
        }
    }

    $self->{_logger}->info("About to create the API in directory '$outdir'");

    my $moduleFileList = [];
    my $testScriptFileList = [];

    foreach my $moduleName (sort keys %{$moduleLookup}){

        my $lookup = $moduleLookup->{$moduleName};

        if ($skipGreenModules){
            if ((exists $moduleLookup->{$moduleName}->{already_implemented}) && ( $moduleLookup->{$moduleName}->{already_implemented} ==  TRUE)){
                $self->{_logger}->info("Will skip creation of module '$moduleName' since UXF indicates the module has already been implemented");
                next;
            }
        }


        my $outfile = $outdir . '/lib/' . $moduleName . '.pm';

        $outfile =~ s|\:\:|/|g;

        my $dirname = File::Basename::dirname($outfile);

        if (!-e $dirname){
            mkpath($dirname) || $self->{_logger}->logconfess("Could not create directory '$dirname' : $!");
            $self->{_logger}->info("Created output directory '$dirname'");
        }

        open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open new output module '$outfile' in write mode : $!");

        &addPackageName($moduleName, $lookup);
        &addProvenanceInfo($outfile);
        &addPackagePod($moduleName, $lookup);
        &addDependencies($moduleName, $lookup);
        &addExtends($moduleName, $lookup);
        &addConstants($moduleName, $lookup);
        &addInstancePrivateMember($moduleName, $lookup);
        &addPrivateDataMembers($moduleName, $lookup);
        &addGetInstanceMethod($moduleName, $lookup);
        &addBuildMethod($moduleName, $lookup, $moduleLookup);
        &addPrivateMethods($moduleName, $lookup);
        &addPublicMethods($moduleName, $lookup);

        if ($moduleName =~ /Factory/){
            &addFactoryModuleSpecificMethods($moduleName, $lookup);
        }



        print OUTFILE "\nno Moose;\n";
        print OUTFILE '__PACKAGE__->meta->make_immutable;' . "\n";

        close OUTFILE;
        
        if ($self->getVerbose()){
            print "Wrote module file '$outfile'\n";
        }

        $self->{_logger}->info("Wrote module file '$outfile'");

        my $testScriptName = &deriveScriptName($moduleName, $outdir);

        &createTestScript($testScriptName, $moduleName, $outdir);


        push(@{$moduleFileList}, $outfile);
        push(@{$testScriptFileList}, $testScriptName);
    }

    if ($self->getVerbose()){
        print "Have created the API in the directory '$outdir'\n";
    }

    print "Created the following test scripts:\n";
    print join("\n", @{$testScriptFileList}) . "\n";

    print "\nCreated the following test scripts:\n";
    print join("\n", @{$moduleFileList}) . "\n";

    $self->{_logger}->info("Have created the API in the directory '$outdir'");
}

sub addPackageName {

    my ($moduleName, $lookup) = @_;
    print OUTFILE "package $moduleName;\n\n";
}

sub addProvenanceInfo {

    my ($outfile) = @_;

    print OUTFILE "##----------------------------------------------\n";
    print OUTFILE "## [RCS_TRIPWIRE] The following are Subversion keyword anchors.\n";
    print OUTFILE "## [RCS_TRIPWIRE] Enable these by executing:\n";
    print OUTFILE "## [RCS_TRIPWIRE] svn propset svn:keywords 'Id Author Date Rev HeadURL' $outfile\n";
    print OUTFILE '## $Id: umlet_to_perl.pl 111 2013-08-09 17:59:02Z sundaramj $ ' . "\n";
    print OUTFILE '## $Author: sundaramj $ ' . "\n";
    print OUTFILE '## $Date: 2013-08-09 13:59:02 -0400 (Fri, 09 Aug 2013) $ ' . "\n";
    print OUTFILE '## $Rev: 111 $ ' . "\n";
    print OUTFILE '## $HeadURL: svn+ssh://sundaramj@10.10.25.250/srv/svn/ctsi-repo/ctsi-utils/trunk/bin/umlet_to_perl.pl $ ' . "\n";
    print OUTFILE "##----------------------------------------------\n\n";

    print OUTFILE "## [RCS_TRIPWIRE] After this module has been reviewed, the following lines can be deleted:\n";
    print OUTFILE "## [RCS_TRIPWIRE] method-created: " . File::Spec->rel2abs($0) . "\n";
    print OUTFILE "## [RCS_TRIPWIRE] date-created: " . localtime() . "\n";
    print OUTFILE "## [RCS_TRIPWIRE] created-by: " . getlogin . "\n";
    print OUTFILE "## [RCS_TRIPWIRE] input-umlet-file: " . File::Spec->rel2abs($infile) . "\n";
    print OUTFILE "## [RCS_TRIPWIRE] output-directory: " . File::Spec->rel2abs($outdir) . "\n";

}

sub addPackagePod {

    my ($moduleName, $lookup) = @_;

    print OUTFILE "\n\n";
    print OUTFILE '=head1 NAME' . "\n\n";
    print OUTFILE ' ' . $moduleName . "\n\n";
    print OUTFILE ' [RCS_TRIPWIRE] INSERT ONE LINE DESCRIPTION HERE.' . "\n\n";
    print OUTFILE '=head1 VERSION' . "\n\n";
    print OUTFILE ' ' . $softwareVersion . "\n\n";
    print OUTFILE '=head1 SYNOPSIS' . "\n\n";
    print OUTFILE ' use ' . $moduleName . ';' . "\n";
    print OUTFILE ' [RCS_TRIPWIRE] INSERT SHORT SYNOPSIS HERE.'. "\n\n";
    print OUTFILE '=head1 AUTHOR' . "\n\n";
    print OUTFILE ' ' . $softwareAuthor  . "\n\n";
    print OUTFILE ' ' . $authorEmailAddress . "\n\n";
    print OUTFILE '=head1 METHODS' . "\n\n";
    print OUTFILE '=over 4' . "\n\n";
    print OUTFILE '=cut' . "\n\n";
}

sub addDependencies {

    my ($moduleName, $lookup) = @_;

    print OUTFILE "\n";
    print OUTFILE "use Moose;\n";

    my $ctr = 0 ;

    if (( exists $lookup->{depends_on_list}) && 
        ( defined $lookup->{depends_on_list})){

        foreach my $dependency (@{$lookup->{depends_on_list}}){
            
            print OUTFILE "use $dependency;\n";
            
            $ctr++;
        }
    }

    if ($self->getVerbose()){
        print "Added '$ctr' dependencies\n";
    }

    $self->{_logger}->info("Added '$ctr' dependencies");
}

sub addExtends {

    my ($moduleName, $lookup) = @_;

    print OUTFILE "\n";

    my $ctr = 0 ;

    if (( exists $lookup->{extends_list}) && 
        ( defined $lookup->{extends_list})){

        foreach my $extends (@{$lookup->{extends_list}}){
            
            print OUTFILE "extends '$extends';\n";
            
            $ctr++;
        }
    }

    if ($self->getVerbose()){
        print "Added '$ctr' extends clauses\n";
    }

    $self->{_logger}->info("Added '$ctr' extends clauses");
}

sub addConstants {

    my ($moduleName, $lookup) = @_;

    my $ctr = 0 ;

    ## Always add the TRUE, FALSE constants to the top of each module
    print OUTFILE "\nuse constant TRUE  => 1;\n";
    print OUTFILE "use constant FALSE => 0;\n";

    if (( exists $lookup->{constant_list}) &&
        ( defined $lookup->{constant_list})){

        print OUTFILE "\n";
        
        foreach my $constantArrayRef (@{$lookup->{constant_list}}){
            
            my $name = $constantArrayRef->[0];
            
            if ((lc($name) eq 'true') || (lc($name) eq 'false')){
                next;
            }

            my $val = $constantArrayRef->[1];
            
            if (!defined($val)){
                $val = undef;
            }

            ## Automatically convert all uppercase
            $name = uc($name);

            print OUTFILE "use constant $name => $val;\n";
            $ctr++;
        }
    }

    if ($self->getVerbose()){
        print "Added '$ctr' constants\n";
    }

    $self->{_logger}->info("Added '$ctr' constants");
}

sub addInstancePrivateMember {

    my ($moduleName, $lookup) = @_;

    if (( exists $lookup->{singleton}) &&
        ( defined $lookup->{singleton})){
        
        print OUTFILE "\n";
        print OUTFILE "## Singleton support\n";
        print OUTFILE 'my $instance;' . "\n\n";

        if ($self->getVerbose()){
            print "Adding Singleton support for module '$moduleName'\n";
        }

        $self->{_logger}->info("Adding Singleton support for module '$moduleName'");
        
    }
    else {
        if ($self->getVerbose()){
            print "module '$moduleName' is not a singleton\n";
        }
    }       

    $self->{_logger}->info("module '$moduleName' is not a singleton");
    
}

sub addGetInstanceMethod {

    my ($moduleName, $lookup) = @_;

    if (( exists $lookup->{singleton}) &&
        ( defined $lookup->{singleton})){

        print OUTFILE 'sub getInstance {' . "\n\n";


        if (! $suppressCheckpoints){
            print OUTFILE '    confess "CHECKPOINT"; ## [RCS_TRIPWIRE] Remove this line of code after reviewing this method.' . "\n\n";
        }

        print OUTFILE '    if (!defined($instance)){' . "\n";
        print OUTFILE '        $instance = new ' . $moduleName . '(@_);' . "\n";
        print OUTFILE '        if (!defined($instance)){' . "\n";
        print OUTFILE '            confess "Could not instantiate ' . $moduleName . "\";\n";
        print OUTFILE '        }' . "\n";
        print OUTFILE '    }' . "\n";
        print OUTFILE '    return $instance;' . "\n";
        print OUTFILE '}' . "\n";
        
        if ($self->getVerbose()){
            print "Added getInstance method\n";
        }

        $self->{_logger}->info("Added getInstance method");
    }
    else {
        if ($self->getVerbose()){
            print "module '$moduleName' is not a singleton\n";
        }

        $self->{_logger}->info("module '$moduleName' is not a singleton");
    }        
}

sub addPrivateDataMembers {

    my ($moduleName, $lookup) = @_;

    my $ctr = 0 ;

    if (( exists $lookup->{private_data_members_list}) &&
        ( defined $lookup->{private_data_members_list})){

        print OUTFILE "\n";
    
        foreach my $arrayRef (@{$lookup->{private_data_members_list}}){
            
            my $name = $arrayRef->[0];
            
            my $datatype = lc($arrayRef->[1]);

            my $isa;

            my $mooseMethodName = ucfirst(lc($name));

            if (($datatype eq 'string') || ($datatype eq 'str')){
                $isa = 'Str';
            }
            elsif (($datatype eq 'int') || ($datatype eq 'integer')){
                $isa = 'Int';
            }
            elsif ($datatype eq 'float'){
                $self->{_logger}->info("Will convert the float data type into Moose Num");
                $isa = 'Num';
            }
            elsif ($datatype eq 'number'){
                $self->{_logger}->info("Will convert the number data type into Moose Num");
                $isa = 'Num';
            }                
            elsif ($datatype =~ /::/){
                $isa = $datatype;
            }
            else {
                $self->{_logger}->logconfess("Unrecognized data type '$datatype'");
            }

            print OUTFILE "has '$name' => (\n";
            print OUTFILE "    is => 'rw',\n";
            print OUTFILE "    isa => '$isa',\n";
            print OUTFILE "    writer => 'set$mooseMethodName',\n";
            print OUTFILE "    reader => 'get$mooseMethodName'";

            if ($name ne lc($name)){

                my $init_arg = decamelize($name);

                print OUTFILE ",\n";
                print OUTFILE "    init_arg => '$init_arg'";
            }

            print OUTFILE "    );\n\n";
            $ctr++;
        }
    }

    if ($self->getVerbose()){
        print "Added '$ctr' private data members\n";
    }
}

sub addBuildMethod {

    my ($moduleName, $lookup) = @_;

    print OUTFILE "\n";
    print OUTFILE "sub BUILD {\n\n";

    if (! $suppressCheckpoints){
        print OUTFILE '    confess "CHECKPOINT"; ## [RCS_TRIPWIRE] Remove this line of code after reviewing this method.' . "\n\n";
    }

    print OUTFILE '    my $self' ." = shift;\n\n";

    my $initMethodLookup = {};
    my $methodToModuleLookup = {};

    my $ctr = 0;

    print OUTFILE '    $self->_initLogger(@_);' . "\n";


    if (( exists $lookup->{depends_on_list}) &&
        ( defined $lookup->{depends_on_list})){

        foreach my $dependency (@{$lookup->{depends_on_list}}){

            my @parts = split(/::/, $dependency);
            
            my $dep = pop(@parts);

            if (lc($dep) eq 'logger'){
                next;
            }

            my $initMethodName = "_init". $dep;
 
            if (exists $methodToModuleLookup->{$initMethodName}){
                my $namespace = pop(@parts);
                $initMethodName = "_init". $namespace. $dep; 
            }

            $methodToModuleLookup->{$initMethodName} = $dependency;

 #           $initMethodLookup->{$initMethodName} = $dependency;
           $initMethodLookup->{$dependency} = $initMethodName;
            
            print OUTFILE '    $self->' . $initMethodName ."(" .'@_' .");\n";
            
            $ctr++;
        }

    }

    print OUTFILE "}\n\n";

    if ($self->getVerbose()){
        print "Added '$ctr' init methods to the BUILD method\n";
    }


    $self->{_logger}->info("Added '$ctr' init methods to the BUILD method");

    &addInitLoggerMethod();

    if ($ctr > 0){

        &addInitMethods($initMethodLookup, $moduleLookup, $moduleName);

#        print "module '$moduleName' initMethodLookup: " . Dumper $initMethodLookup;
    }
}
    
sub addInitLoggerMethod {

    print OUTFILE "sub _initLogger {\n\n";
    print OUTFILE '    my $self = shift;' . "\n\n";
    print OUTFILE '    my $self->{_logger} = Log::Log4perl->get_logger(__PACKAGE__);' . "\n";
    print OUTFILE '    if (!defined($self->{_logger})){' . "\n";
    print OUTFILE '        confess "logger was not defined";' . "\n";
    print OUTFILE "    }\n\n";
    print OUTFILE '    $self->{_logger} = $self->{_logger};' . "\n";
    print OUTFILE "}\n";
}

sub addInitMethods {

    my ($initMethodLookup, $moduleLookup, $moduleName) = @_;

    print OUTFILE "\n";

    my $ctr = 0;

    foreach my $module (sort {$a <=> $b } keys %{$initMethodLookup}){

        if (exists $moduleLookup->{$moduleName}->{factory_types_lookup}->{$module}){
            next;
        }

        my $method = $initMethodLookup->{$module};

        if ($method eq '_initLogger'){
            next;
        }

#        my $module = $initMethodLookup->{$method};

        my @parts = split(/::/, $module);

        my $moduleBasename = pop(@parts);
        
        my $moduleVar = lc($moduleBasename);

        print OUTFILE "sub $method {\n\n";

        if (! $suppressCheckpoints){
            print OUTFILE '    confess "CHECKPOINT"; ## [RCS_TRIPWIRE] Remove this line of code after reviewing this method.' . "\n\n";
        }
        
        print OUTFILE '    my $self = shift;'."\n\n";

        if (( exists $moduleLookup->{$module}->{singleton}) && 
            ( defined $moduleLookup->{$module}->{singleton})){
            print OUTFILE '    my $' . $moduleVar . ' = ' . $module . '::getInstance(@_);' . "\n";
        }
        else {
            print OUTFILE '    my $' . $moduleVar . ' = new ' . $module . '(@_);' . "\n";
        }
        print OUTFILE '    if (!defined($' . $moduleVar. ')){' . "\n";
        print OUTFILE '        $self->{_logger}->logconfess("Could not instantiate ' . $module .'");' ."\n";
        print OUTFILE "    }\n\n";
        print OUTFILE '    $self->{_' .$moduleVar . '} = $'. $moduleVar . ";\n";
        print OUTFILE "}\n\n";
        
        
        $ctr++;
    }

    if ($self->getVerbose()){
        print "Added '$ctr' init methods\n";
    }

    $self->{_logger}->info("Added '$ctr' init methods");
}





sub addPublicMethods {

    my ($moduleName, $lookup) = @_;

    my $ctr = 0;

    if (( exists $lookup->{public_methods_list}) && 
        ( defined $lookup->{public_methods_list})){
        
        &addMethods($moduleName, $lookup, 'public');
    }
}

sub addPrivateMethods {

    my ($moduleName, $lookup) = @_;

    if (( exists $lookup->{private_methods_list}) && 
        ( defined $lookup->{private_methods_list})){
        
        &addMethods($moduleName, $lookup, 'private');
    }
}
            
sub addMethods {

    my ($moduleName, $lookup, $methodType) = @_;

    my $methodTypeKey = 'public_methods_list';

    if ($methodType eq 'private'){
        $methodTypeKey = 'private_methods_list';
    }

    my $ctr = 0;

    foreach my $arrayRef (@{$lookup->{$methodTypeKey}}){

        my $methodName = $arrayRef->[0];

        if ($methodType eq 'private'){
            $methodName = '_' . $arrayRef->[0];
        }

        ## Add the POD first
        print OUTFILE '=item ' . $methodName . '()' . "\n\n";
        print OUTFILE 'B<Description:> INSERT BRIEF DESCRIPTION HERE' . "\n\n";
        print OUTFILE 'B<Parameters:> INSERT PARAMETERS HERE' . "\n\n";
        print OUTFILE 'B<Returns:> INSERT RETURNS HERE' . "\n\n";
        print OUTFILE '=cut' . "\n\n";

        ## Add the method definition
        print OUTFILE 'sub ' . $methodName . " {\n\n";

        print OUTFILE '    my $self = shift;'."\n";
        
        
        my $parameterList = $arrayRef->[1];

        if (defined($parameterList)){

            $self->{_logger}->info("Will add parameters '$parameterList' to method '$methodName'");

            $parameterList =~ s/\s//g; ## Remove all whitespaces 

            my @paramList = split(',', $parameterList);


            my @argumentList;

            foreach my $param (@paramList){
                
                push(@argumentList, '$'. $param);
            }

            my $argList = '    my (' . join(', ', @argumentList) . ') = @_;';                

            print OUTFILE $argList . "\n\n";
            
            foreach my $param (@paramList){

                print OUTFILE '    if (!defined($' . $param . ')){' . "\n";
                print OUTFILE '        $self->{_logger}->logconfess("' . $param . ' was not defined");' . "\n";
                print OUTFILE '    }' . "\n\n";
            }


        }
        else {
            $self->{_logger}->info("There were no parameters for method '$methodName'");
        }


        print OUTFILE "\n    confess \"NOT YET IMPLEMENTED\"; ## [RCS_TRIPWIRE]\n\n";

        my $returnDataType = $arrayRef->[2];

        if (defined($returnDataType)){
            print OUTFILE '    my $returnVal; ## [RCS_TRIPWIRE] Should be defined as data type ' . $returnDataType . "\n\n";
            print OUTFILE '    return $returnVal;' . "\n";
        }
        else {
            $self->{_logger}->info("There was no return data type for method '$methodName'");
        }           

        print OUTFILE "}\n\n";

        $ctr++;
    }


    if ($self->getVerbose()){
        print "Added '$ctr' $methodType methods\n";
    }

    $self->{_logger}->info("Added '$ctr' $methodType methods");
}


sub deriveScriptName {

    my ($moduleName, $outdir) = @_;


    if ($moduleName =~ /::/){

    my @parts = split(/::/, $moduleName);

    my $name = pop(@parts);

    my $testScriptName = 'test' . $name . '.pl';

    my $subdirName = join('::', @parts);

    $subdirName =~ s/::/\//g;

    my $dir = $outdir . '/test/' . $subdirName;

    if (!-e $dir){

        mkpath($dir) || $self->{_logger}->logconfess("Could not create directory '$dir' : $!");

        $self->{_logger}->info("Created directory '$dir'");
    }
    
    my $fqdName = $dir . '/' . $testScriptName;

    return $fqdName;
    }
    else {
        $self->{_logger}->logconfess("Don't know how to process module '$moduleName'");
    }
}

sub createTestScript {

    my ($scriptName, $module, $outdir) = @_;

    if (-e $scriptName){

    my $bakfile = $scriptName . '.bak';

    copy ($scriptName, $bakfile) || $self->{_logger}->logconfess("Could not copy '$scriptName' to '$bakfile' : $!");
    }

    open (TOUTFILE, ">$scriptName") || $self->{_logger}->logconfess("Could not open file '$scriptName' in write mode : $!");


    print TOUTFILE '#!/usr/bin/perl' . "\n";

    print TOUTFILE "##----------------------------------------------\n";
    print TOUTFILE "## The following are Subversion keyword anchors.\n";
    print TOUTFILE "## Enable these by executing:\n";
    print TOUTFILE "## svn propset svn:keywords 'Id Author Date Rev HeadURL' $scriptName\n";
    print TOUTFILE '## $Id: umlet_to_perl.pl 111 2013-08-09 17:59:02Z sundaramj $ ' . "\n";
    print TOUTFILE '## $Author: sundaramj $ ' . "\n";
    print TOUTFILE '## $Date: 2013-08-09 13:59:02 -0400 (Fri, 09 Aug 2013) $ ' . "\n";
    print TOUTFILE '## $Rev: 111 $ ' . "\n";
    print TOUTFILE '## $HeadURL: svn+ssh://sundaramj@10.10.25.250/srv/svn/ctsi-repo/ctsi-utils/trunk/bin/umlet_to_perl.pl $ ' . "\n";
    print TOUTFILE "##----------------------------------------------\n\n";

    print TOUTFILE 'use strict;' . "\n";
    print TOUTFILE 'use ' . $module . ';' . "\n\n";


    print TOUTFILE "## method-created: " . File::Spec->rel2abs($0) . "\n";
    print TOUTFILE "## date-created: " . localtime() . "\n";
    print TOUTFILE "## created-by: " . getlogin . "\n";
    print TOUTFILE "## input-umlet-file: " . File::Spec->rel2abs($infile) . "\n";
    print TOUTFILE "## output-directory: " . File::Spec->rel2abs($outdir) . "\n\n";

    print TOUTFILE 'my $var = new ' . $module . '();' ."\n";
    print TOUTFILE 'if (!defined($var)){' . "\n";
    print TOUTFILE '    die "Could not instantiate '. $module . "\";\n";
    print TOUTFILE '}' . "\n\n";

    print TOUTFILE 'print "$0 execution completed\n";' ."\n";
    print TOUTFILE 'exit(0);' . "\n\n";

    print TOUTFILE '##---------------------------------------------------' ."\n";
    print TOUTFILE '##' . "\n";
    print TOUTFILE '##  END OF MAIN -- SUBROUTINES FOLLOW' . "\n";
    print TOUTFILE '##' . "\n";
    print TOUTFILE '##---------------------------------------------------' ."\n";
    
    close TOUTFILE;

    $self->{_logger}->info("Wrote '$scriptName'");
}


sub addFactoryModuleSpecificMethods {

    my ($moduleName, $lookup) = @_;


    &addFactoryGetTypeMethod($moduleName, $lookup);
    &addFactoryCreateMethod($moduleName, $lookup);
}

sub addFactoryGetTypeMethod {

    my ($moduleName, $lookup) = @_;

    if (! $suppressCheckpoints){
        print OUTFILE '    confess "CHECKPOINT"; ## [RCS_TRIPWIRE] Remove this line '.
            'of code after reviewing this method.' . "\n\n";
    }

    print OUTFILE 'sub _getType {' . "\n\n";
    print OUTFILE '    my $self = shift;' . "\n";
    print OUTFILE '    my (%args) = @_;' . "\n\n";
    print OUTFILE '    my $type = $self->getType();' . "\n\n";
    print OUTFILE '    if (!defined($type)){' . "\n\n";
    print OUTFILE '        if (( exists $args{system_type}) && ( defined $args{system_type})){' . "\n";
    print OUTFILE '            $type = $args{system_type};' . "\n";
    print OUTFILE '        }' . "\n";
    print OUTFILE '        elsif (( exists $self->{_system_type}) && ( defined $self->{_system_type})){' . "\n";
    print OUTFILE '            $type = $self->{_system_type};' . "\n";
    print OUTFILE '        }' . "\n";
    print OUTFILE '        else {' . "\n";
    print OUTFILE '            $self->{_logger}->logconfess("type was not defined");' . "\n";
    print OUTFILE '        }' . "\n\n";
    print OUTFILE '        $self->setType($type);' . "\n";
    print OUTFILE '    }' . "\n\n";
    print OUTFILE '    return $type;' . "\n";
    print OUTFILE '}' . "\n\n";

    $self->{_logger}->info("Added _getType method for module '$moduleName'");
}

   
sub addFactoryCreateMethod {

    my ($moduleName, $lookup) = @_;

    print OUTFILE 'sub create {' . "\n\n";


    if (! $suppressCheckpoints){
        print OUTFILE '    confess "CHECKPOINT"; ## [RCS_TRIPWIRE] Remove this '.
            'line of code after reviewing this method.' . "\n\n";
    }

    print OUTFILE '    my $type  = $self->_getType(@_);' . "\n\n";
    
    my $typeCtr = 0;

    foreach my $depmod (sort {$a <=> $b } keys %{$lookup->{factory_types_lookup}}){

        $typeCtr++;

        my $type = $lookup->{factory_types_lookup}->{$depmod};

        my $lctype = lc($type);
        my @parts = split('::', $depmod);
        my $varname = lc(pop@parts);

        if ($typeCtr == 1){
            print OUTFILE '    if (lc($type) eq \'' . $lctype . "'){" . "\n\n";
        }
        else {
            print OUTFILE '    elsif (lc($type) eq \'' . $lctype . "'){" . "\n\n";
        }

        print OUTFILE '        my $' . $varname . ' = new ' . $depmod . '(@_);' . "\n";
        print OUTFILE '        if (!defined($' . $varname . ')){' . "\n";
        print OUTFILE '            confess "Could not instantiate ' . $depmod . "\";\n";
        print OUTFILE '        }' . "\n\n";
        print OUTFILE '        return $' . $varname . ';' . "\n";
        print OUTFILE '    }' . "\n";
    }
    
    print OUTFILE '    else {' . "\n";
    print OUTFILE '        confess "type \'$type\' is not currently supported";' . "\n";
    print OUTFILE '    }' . "\n";
    print OUTFILE '}' . "\n\n";
    
    if ($self->getVerbose()){
        print "Wrote create method for module '$moduleName'\n";
    }
    
    $self->{_logger}->info("Wrote create method for module '$moduleName'");
}



no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Perl::Module::File::Writer
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Perl::Module::File::Writer;
 my $manager = DevelopmentUtils::Perl::Module::File::Writer::getInstance();
 $manager->commitCodeAndPush($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
