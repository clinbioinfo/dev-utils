package DevelopmentUtils::Alias::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Compare;
use File::Copy;
use FindBin;
use File::Slurp;
use Term::ANSIColor;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_BASHRC_CONFIG_FILE=> "$FindBin::Bin/../doc/aliases.txt";

use constant DEFAULT_USERNAME => $login;

use constant DEFAULT_SOURCE_ALIASES_FILE => "$FindBin::Bin/../doc/aliases.txt";


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

has 'source_aliases_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSourceAliasesFile',
    reader   => 'getSourceAliasesFile',
    required => FALSE,
    default  => DEFAULT_SOURCE_ALIASES_FILE
    );

has 'bashrc_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setBashrcFile',
    reader   => 'getBashrcFile',
    required => FALSE
    );

has 'username' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setUsername',
    reader   => 'getUsername',
    required => FALSE,
    default  => DEFAULT_USERNAME
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Alias::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Alias::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_set_default_bashrc_file(@_);

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

sub _set_default_bashrc_file {

    my $self = shift;
    
    my $file = $self->getBashrcFile();

    if (!defined($file)){

        $file = '/home/' . $self->getUsername() . '/.bashrc';
        
        $self->setBashrcFile($file);
    }
}

sub checkAliases {

    my $self = shift;

    my $bashrc_file = $self->getBashrcFile();

    my $source_aliases_file = $self->getSourceAliasesFile();

    my $installed_aliases_lookup = $self->_load_alias_lookup($bashrc_file);

    my $repo_aliases_lookup = $self->_load_alias_lookup($source_aliases_file);

    my $need_to_save_aliases_list = [];

    my $need_to_save_aliases_ctr = 0;

    my $need_to_install_aliases_list = [];

    my $need_to_install_aliases_ctr = 0;


    foreach my $installed_alias (sort keys %{$installed_aliases_lookup}){

        if (! exists $repo_aliases_lookup->{$installed_alias}){

            my $val = $installed_aliases_lookup->{$installed_alias};

            push(@{$need_to_save_aliases_list}, [$installed_alias, $val]);

            $need_to_save_aliases_ctr++;
        }    
    }


    foreach my $repo_alias (sort keys %{$repo_aliases_lookup}){

        if (! exists $installed_aliases_lookup->{$repo_alias}){

            my $val = $repo_aliases_lookup->{$repo_alias};

            push(@{$need_to_install_aliases_list}, [$repo_alias, $val]);

            $need_to_install_aliases_ctr++;
        }    
    }


    if ($need_to_install_aliases_ctr > 0){
        
        printYellow("Need to install the following '$need_to_install_aliases_ctr' aliases to '$bashrc_file':");
        
        foreach my $alias_list_ref (@{$need_to_install_aliases_list}){
        
            my $alias_name = $alias_list_ref->[0];
        
            my $alias_val  = $alias_list_ref->[1];
        
            print "alias $alias_name=$alias_val\n";
        # print join("\n", @{$need_to_install_aliases_list}) . "\n";
        }
    }

    if ($need_to_save_aliases_ctr > 0){

        printYellow("Need to save the following '$need_to_save_aliases_ctr' aliases to '$source_aliases_file':");
    
        foreach my $alias_list_ref (@{$need_to_save_aliases_list}){
        
            my $alias_name = $alias_list_ref->[0];
        
            my $alias_val  = $alias_list_ref->[1];
        
            print "alias $alias_name=$alias_val\n";
        }
        # print join("\n", @{$need_to_save_aliases_list}) . "\n";
    }
}


# sub installAliases {

#     my $self = shift;

#     my $bashrc_file = $self->getBashrcFile();

#     my $source_alias_file = $self->getSourceAliasFile();

#     printYellow("Going to add aliases to '$bashrc_file' from '$source_alias_file' if the aliases don't already exist there");
    

#     my $currently_installed_aliases_lookup = $self->_load_alias_lookup($bashrc_file);

#     my $source_aliases_lookup = $self->_load_alias_lookup($source_alias_file);


#     my $need_to_save_aliases_list = [];

#     my $need_to_save_aliases_ctr = 0;

#     my $need_to_install_aliases_list = [];

#     my $need_to_install_aliases_ctr = 0;


#     foreach my $installed_alias (sort keys %{$installed_aliases_lookup}){

#         if (! exists $repo_aliases_lookup->{$installed_alias}){

#             push(@{$need_to_save_aliases_list}, $installed_alias);

#             $need_to_save_aliases_ctr++;
#         }    
#     }


#     foreach my $repo_alias (sort keys %{$repo_aliases_lookup}){

#         if (! exists $installed_aliases_lookup->{$repo_alias}){

#             push(@{$need_to_install_aliases_list}, $repo_alias);

#             $need_to_install_aliases_ctr++;
#         }    
#     }


#     if ($need_to_install_aliases_ctr > 0){
#         printYellow("Need to install the following '$need_to_install_aliases_ctr' aliases:");
#         print join("\n", @{$need_to_install_aliases_list}) . "\n";
#     }

#     if ($need_to_save_aliases_ctr > 0){
#         printYellow("Need to save the following '$need_to_save_aliases_ctr' aliases:");
#         print join("\n", @{$need_to_save_aliases_list}) . "\n";
#     }
# }




sub _load_alias_lookup {

    my $self = shift;
    my ($file) = @_;

    my @lines = read_file($file);

    my $lookup = {};

    foreach my $line (@lines){

        chomp $line;

        $line =~ s|\s*$||;

        if ($line =~ m|^alias\s(\S+)=(.+)|){

            $lookup->{$1} = $2;
        }
    }


    return $lookup;
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

 DevelopmentUtils::Alias::Manager
 A module for managing aliases.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Alias::Manager;
 my $manager = DevelopmentUtils::Alias::Manager::getInstance();
 $manager->checkAliases();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
