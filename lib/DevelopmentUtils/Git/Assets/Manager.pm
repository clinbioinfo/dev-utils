package DevelopmentUtils::Git::Assets::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'json_file_to_perl';

use DevelopmentUtils::Logger;
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

has 'report_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setReportFile',
    reader   => 'getReportFile',
    required => FALSE
    );

has 'project' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProject',
    reader   => 'getProject',
    required => FALSE
    );

has 'checkout_directory' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCheckoutDirectory',
    reader   => 'getCheckoutDirectory',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Assets::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Assets::Manager";
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

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
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

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print $msg . "\n";
    print color 'reset';
}

sub manageAssets {

    my $self = shift;
    
    $self->_compare_assets(@_);

    if ($self->{_need_to_commit_assets}){

        $self->_commit_assets(@_);
    }
    else {
        
        $self->{_logger}->info("No assets need to be committed.");
        
        printBrightBlue("No assets need to be committed");
    }
}

sub _commit_assets {

    my $self = shift;

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");
}

sub _compare_assets {

    my $self = shift;

    my $lookup1 = $self->_load_lookup($self->getIndir());

    my $lookup2 = $self->_load_lookup($self->getCheckoutDirectory());

    my $missing_ctr = 0;
    my $missing_list = [];

    my $changed_ctr = 0;
    my $changed_list = [];

    foreach my $file (sort keys %{$lookup1}){

        my $file1_path = $lookup1->{$file};

        if (!exists $lookup2->{$file}){

            push(@{$missing_list}, [$file, $file1_path]);

            $missing_ctr++;
        }
        else {
            my $file2_path = $lookup2->{$file};

            if (compare($file1_path, $file2_path) == 0){

                $self->{_logger}->info("file '$file1_path' matches '$file2_path'");
                
                next;
            }
            else {

                push(@{$changed_list}, [$file, $file1_path, $file2_path]);
                
                $changed_ctr++;
            }
        }
    }

    if ($missing_ctr > 0){

        printBoldRed("The following '$missing_ctr' files need to be added to the repository");
    
        foreach my $list_ref (@{$missing_list}){

            my $file_path = $list_ref->[1];

            print "\t$file_path\n";
        }
        
        $self->{_missing_list} = $missing_list;

        $self->{_missing_ctr} = $missing_ctr;
    }

    if ($changed_ctr > 0){

        printBoldRed("The following '$changed_ctr' files have changed (these need to be committed to the repository):");

        foreach my $list_ref (@{$changed_list}){

            my $file_path = $list_ref->[1];
            
            print "\t$file_path\n";
        }

        $self->{_changed_list} = $changed_list;

        $self->{_changed_ctr} = $changed_ctr;
    }
}

sub _load_lookup {

    my $self = shift;
    my ($dir) = @_;

    $self->checkIndirectoryStatus($dir);

    my $cmd = "find $dir -type f";

    my $results = $self->_execute_cmd($cmd);

    my $lookup = {};

    my $file_ctr = 0;

    foreach my $file (@{$results}){

        $file_ctr++;

        my $key = $file;

        $key =~ s|$dir||;

        $lookup->{$key} = $file;
    }

    $self->{_logger}->info("Found '$file_ctr' files in directory '$dir'");

    return $lookup;
}

sub checkIndirectoryStatus {

    my $self = shift;
    my ($indir) = @_;

    if (!defined($indir)){
        $self->{_logger}->logconfess("indir was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $indir){
        
        $self->{_logger}->warn("input directory '$indir' does not exist");
        
        $errorCtr++;
    }
    else {

        if (!-d $indir){
        
            $self->{_logger}->warn("'$indir' is not a regular directory");
            
            $errorCtr++;
        }

        if (!-r $indir){
            
            $self->{_logger}->warn("input directory '$indir' does not have read permissions");
            
            $errorCtr++;
        }        
    }
     
    if ($errorCtr > 0){
        
        $self->{_logger}->warn("Encountered issues with input directory '$indir'");
        
    }
}

sub _execute_cmd {
    
    my $self = shift;
    
    my ($cmd) = @_;
    if (!defined($cmd)){
        $self->{_logger}->logconfess("cmd was not defined");
    }

    $self->{_logger}->info("About to execute '$cmd'");

    my @results;

    eval {
        @results = qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @results;

    return \@results;
}    


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Assets::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Assets::Manager;
 my $manager = DevelopmentUtils::Git::Assets::Manager::getInstance();
 $manager->commitCodeAndPush($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
