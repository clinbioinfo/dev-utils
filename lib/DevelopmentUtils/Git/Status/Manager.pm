package DevelopmentUtils::Git::Status::Manager;

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

use constant DEFAULT_VERBOSE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

## Singleton support
my $instance;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

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

has 'commit_asset_list_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitAssetListFile',
    reader   => 'getCommitAssetListFile',
    required => FALSE
    );



sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Status::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Status::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_modified_staged_file_list} = [];
    $self->{_modified_staged_file_ctr} = 0;

    $self->{_deleted_staged_file_list} = [];
    $self->{_deleted_staged_file_ctr} = 0;

    $self->{_modified_not_staged_file_list} = [];
    $self->{_modified_not_staged_file_ctr} = 0;

    $self->{_deleted_not_staged_file_list} = [];
    $self->{_deleted_not_staged_file_ctr} = 0;
    
    $self->{_untracked_file_list} = [];
    $self->{_untracked_file_ctr} = 0;

    $self->{_has_uncommitted_assets} = FALSE;

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

sub checkForUncommittedAssets {


    my $self = shift;

    return $self->_get_asset_list_content(@_);
}

sub _get_asset_list_content {

    my $self = shift;

    my $asset_file = $self->getCommitAssetListFile();

    if (!defined($asset_file)){
    
        $self->{_logger}->info("asset_file was not defined");
    
        $asset_file = $self->getOutdir() . '/asset-list-file.txt';

        $self->setCommitAssetListFile($asset_file);

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    if (!-e $asset_file){

        $self->{_logger}->info("asset list file '$asset_file' does not exist");

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    $self->_parse_asset_list_file($asset_file);

   return $self->{_has_uncommitted_assets};

}

sub _parse_asset_list_file {

    my $self = shift;
    my ($asset_file) = @_;

    my @content = read_file($asset_file);

    my $asset_content_list;

    my $found_modified_not_staged_section = FALSE;
    my $found_modified_staged_section = FALSE;
    my $found_untracked_files_section = FALSE;    
    my $found_the_end = FALSE;

    foreach my $line (@content){

        chomp $line;

        if ($line =~ /^\s*$/){
            next;
        }

        if ($line =~ /^\s*\(/){
            $self->{_logger}->info("Ignoring this line '$line'");
            next;
        }
        elsif ($line =~ m|On branch |){
            next;
        }
        elsif ($line eq "nothing to commit, working directory clean"){
            last;
        }
        elsif ($line =~ m|^Changes to be committed:|){

            if ($self->getVerbose()){
                print "Found changes (staged) to be committed\n";
            }
        
            $found_modified_staged_section = TRUE;
            
            $found_modified_not_staged_section = TRUE;

            $found_untracked_files_section = FALSE;        

            next;
        }
        elsif ($line =~ m|^Changes not staged for commit:|){

            if ($self->getVerbose()){
                print "Found changes not staged for commit\n";
            }
        
            $found_modified_not_staged_section = TRUE;

            $found_modified_staged_section = FALSE;

            $found_untracked_files_section = FALSE;        

            next;
        }
        elsif ($line =~ m|^Untracked files:|){
        
            if ($self->getVerbose()){
                print "Found untracked files section\n";
            }

            $found_untracked_files_section = TRUE;
            
            $found_modified_staged_section = FALSE;

            $found_modified_not_staged_section = FALSE;

            next;
        }
        elsif ($line =~ m|no changes added to commit|){

            if ($self->getVerbose()){
                print "Found end section\n";
            }

            $found_the_end = TRUE;

            $found_untracked_files_section = FALSE;
            
            $found_modified_staged_section = FALSE;

            $found_modified_not_staged_section = FALSE;
        } 
        else {

            if ($found_modified_staged_section){

                if ($line =~ m|^\s+modified:\s+(.+)\s*$|){

                    my $file = $1;

                    if (!-e $file){
                        $self->{_logger}->logconfess("modified staged file '$file' does not exist");
                    }

                    push(@{$self->{_modified_staged_file_list}}, $file);

                    $self->{_modified_staged_file_ctr}++;                
                }
                elsif ($line =~ m|^\s+deleted:\s+(.+)\s*$|){

                    my $file = $1;

                    push(@{$self->{_deleted_staged_file_list}}, $file);

                    $self->{_deleted_staged_file_ctr}++;                

                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }

                next;
            }
            elsif ($found_modified_not_staged_section){

                if ($line =~ m|^\s+modified:\s+(.+)\s*$|){

                    my $file = $1;

                    if (!-e $file){
                        $self->{_logger}->logconfess("modified, not staged file '$file' does not exist");
                    }

                    push(@{$self->{_modified_not_staged_file_list}}, $file);

                    $self->{_modified_not_staged_file_ctr}++;                
                }
                elsif ($line =~ m|^\s+deleted:\s+(.+)\s*$|){

                    my $file = $1;

                    push(@{$self->{_deleted_not_staged_file_list}}, $file);

                    $self->{_deleted_not_staged_file_ctr}++;                

                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }

                next;
            }
            elsif ($found_untracked_files_section){

                if ($line =~ m|^\s+(\S+)\s*$|){

                    my $untracked_file = $1;

                    if (!-e $untracked_file){
                        $self->{_logger}->logconfess("untracked file '$untracked_file' does not exist");
                    }

                    push(@{$self->{_untracked_file_list}}, $untracked_file);

                    $self->{_untracked_file_ctr}++;
                }
                elsif ($line eq 'nothing added to commit but untracked files present (use "git add" to track)'){
                    next;
                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }
            }
        }
    }

    if (($self->{_modified_staged_file_ctr} == 0)  && 
        ($self->{_modified_not_staged_file_ctr} == 0)  && 
        ($self->{_deleted_staged_file_ctr} == 0)  && 
        ($self->{_deleted_not_staged_file_ctr} == 0)  && 
        ($self->{_untracked_file_ctr} == 0)){

        $self->{_has_uncommitted_assets} = FALSE;
    }
    else {

        $self->{_has_uncommitted_assets} = TRUE;
    }
}


sub _derive_asset_list_file_via_status {

    my $self = shift;
    my ($asset_file) = @_;

    my $cmd = "git status";

    my $results = $self->_execute_cmd($cmd);

    open (OUTFILE, ">$asset_file") || $self->{_logger}->logconfess("Could not open '$asset_file' in write mode : $!");
    
    foreach my $line (@{$results}){
        print OUTFILE $line . "\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote to '$asset_file'");
}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;
    
    my @results;
 
    $self->{_logger}->info("About to execute '$cmd'");
    
    eval {
    	@results = qx($cmd);
    };

    if ($?){
    	$self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }


    chomp @results;

    return \@results;
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


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Status::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Status::Manager;
 my $manager = DevelopmentUtils::Git::Status::Manager::getInstance();
 my $asset_list_content = $manager->getAssetListContent();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
