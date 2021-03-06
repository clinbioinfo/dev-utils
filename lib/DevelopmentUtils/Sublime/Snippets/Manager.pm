package DevelopmentUtils::Sublime::Snippets::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Compare;
use File::Copy;
use FindBin;
# use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => FALSE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_INSTALL_DIR => $ENV{HOME} . '/.config/sublime-text-3/Packages/User/';

use constant DEFAULT_REPO_DIR => "$FindBin::Bin/../sublime-snippets/snippets/";

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

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
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

has 'install_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInstallDir',
    reader   => 'getInstallDir',
    required => FALSE,
    default  => DEFAULT_INSTALL_DIR
    );

has 'repo_dir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setRepoDir',
    reader   => 'getRepoDir',
    required => FALSE,
    default  => DEFAULT_REPO_DIR
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Sublime::Snippets::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Sublime::Snippets::Manager";
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

sub checkSnippets {

    my $self = shift;

    my $install_dir = $self->getInstallDir();

    my $repo_dir = $self->getRepoDir();

    my $file_list = $self->_get_file_list($install_dir);

    my $file_ctr = 0;
    my $copy_ctr = 0;
    my $already_exists_ctr = 0;
    my $already_exists_list = [];

    foreach my $file (@{$file_list}){

        $file_ctr++;
        
        my $repo_file = $repo_dir . '/' . File::Basename::basename($file);

        if (!-e $repo_file){

            copy($file, $repo_file) || $self->{_logger}->("Encountered some error while attempting to copy file '$file' to '$repo_file' : $!");
            
            $copy_ctr++;
        }
        else {

            if (compare($file, $repo_file) == 0){

                $already_exists_ctr++;

                push(@{$already_exists_list}, $file);

            }
            else {

                print "repository file '$repo_file' already exists\n";

                printYellow("The contents are different");

                print "You might want to compare the contents of both files and make a decision how you want to proceed\n";

                print "diff $file $repo_file | less\n\n";
            }
        }
    }

    print "Processed '$file_ctr' Sublime snippet files\n";

    if ($copy_ctr > 0){
        
        print "Copied '$copy_ctr' files from '$install_dir' to '$repo_dir'\n";
        
        print "You should commit those to the Git repository\n";

        $self->{_logger}->info("Copied '$copy_ctr' files from '$install_dir' to '$repo_dir'. You should commit those to the Git repository");

    }

    if ($already_exists_ctr > 0){

        if ($self->getVerbose()){

            printYellow("The following '$already_exists_ctr' Sublime snippet files exist in the repository directory and have the same content:");

            print join("\n",  @{$already_exists_list}) . "\n";
        }


        $self->{_logger}->info("The following '$already_exists_ctr' Sublime snippet files exist in the repository directory and have the same content:");

        $self->{_logger}->info(join("\n",  @{$already_exists_list}));
    }
}


sub _get_file_list {

    my $self = shift;
    my ($dir) = @_;

    my $cmd = "find $dir -name '*.sublime-snippet'";

    my @file_list;

    print "About to execute '$cmd'\n";

    $self->{_logger}->info("About to execute '$cmd'");


    eval {
        @file_list = qx($cmd);
    };

    if($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }

    chomp @file_list;

    return \@file_list;
}

sub installSublimeSnippets {

    my $self = shift;
    my ($install_dir, $source_dir) = @_;

    if (!defined($install_dir)){

        $install_dir = $self->getInstallDir();

        if (!defined($install_dir)){

            $self->{_logger}->logconfess("install_dir was not defined");
        }
    }

    if (!defined($source_dir)){

        $source_dir = $self->getRepoDir();

        if (!defined($source_dir)){

            $self->{_logger}->logconfess("source_dir was not defined");
        }
    }

    my $file_list = $self->_get_file_list($source_dir);

    my $file_ctr = 0;
    my $copy_ctr = 0;
    my $already_exists_ctr = 0;
    my $already_exists_list = [];

    foreach my $file (@{$file_list}){

        $file_ctr++;
        
        my $target_file = $install_dir . '/' . File::Basename::basename($file);

        $target_file =~ s|/+|/|g;  ## remove multiple forward slashes

        if (!-e $target_file){

            copy($file, $target_file) || $self->{_logger}->logconfess("Encountered some error while attempting to copy file '$file' to '$target_file' : $!");
            
            $copy_ctr++;
        }
        else {

            if (compare($file, $target_file) == 0){

                $already_exists_ctr++;

                push(@{$already_exists_list}, $file);

            }
            else {

                print "target file '$target_file' already exists\n";

                $self->{_logger}->info("target file '$target_file' already exists");

                printYellow("The contents are different");

                print "You might want to compare the contents of both files and make a decision how you want to proceed\n";

                print "diff $file $target_file | less\n\n";
            }
        }
    }

    print "Processed '$file_ctr' Sublime snippet files\n";

    $self->{_logger}->info("Processed '$file_ctr' Sublime snippet files");

    print "Copied '$copy_ctr' files from '$source_dir' to '$install_dir'\n";

    $self->{_logger}->info("Copied '$copy_ctr' files from '$source_dir' to '$install_dir'");

    if ($already_exists_ctr > 0){

        if ($self->getVerbose()){

            printYellow("The following '$already_exists_ctr' Sublime snippet files existed in the target install directory and have the same content:");

            print join("\n",  @{$already_exists_list}) . "\n";
        }

        $self->{_logger}->info("The following '$already_exists_ctr' Sublime snippet files existed in the target install directory and have the same content:");

        $self->{_logger}->info(join("\n",  @{$already_exists_list}));
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

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Sublime::Snippets::Manager
 A module for managing Sublime Snippet files.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Sublime::Snippets::Manager;
 my $manager = DevelopmentUtils::Sublime::Snippets::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
