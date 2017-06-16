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

my $login =  getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_USERNAME => $login;

use constant DEFAULT_SOURCE_FILE => "$FindBin::Bin/../doc/aliases.txt";


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

has 'source_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setSourceFile',
    reader   => 'getSourceFile',
    required => FALSE,
    default  => DEFAULT_SOURCE_FILE
    );

has 'target_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTargetFile',
    reader   => 'getTargetFile',
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

    $self->_set_default_target_file(@_);

    $self->{_installed_new_aliases_file} = FALSE;
    
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

sub _set_default_target_file {

    my $self = shift;
    
    my $file = $self->getTargetFile();

    if (!defined($file)){

        $file = '/home/' . $self->getUsername() . '/aliases.txt';
        
        $self->setTargetFile($file);
    }
}

sub _check_target_file {

    my $self = shift;
    my ($source_file, $target_file) = @_;

    if (!-e $target_file){

        my $username = $self->getUsername();

        if (!defined($username)){
            $self->{_logger}->logconfess("username was not defined");
        }

        $target_file = '/home/'. $username . '/aliases.txt';

        if (!-e $target_file){

            copy($source_file, $target_file) || $self->{_logger}->logconfess("Could not copy '$source_file' to '$target_file' : $!");
            
            $self->{_logger}->info("Copied '$source_file' to '$target_file'");
            
            print "Copied '$source_file' to '$target_file\n";
            
            printYellow("Make sure you add 'source $target_file' to ~/.bashrc");

            $self->{_installed_new_aliases_file} = TRUE;            
        }
    }
}

sub checkAliases {

    my $self = shift;

    my $target_file = $self->getTargetFile();

    my $source_file = $self->getSourceFile();

    $self->_check_target_file($source_file, $target_file);

    if ($self->{_installed_new_aliases_file}){
     
        $self->{_logger}->info("Just installed new aliases.txt file.  No further processing required.");
     
        return
    }

    my $installed_aliases_lookup = $self->_load_alias_lookup($target_file);

    my $repo_aliases_lookup = $self->_load_alias_lookup($source_file);

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
        
        printYellow("Need to install the following '$need_to_install_aliases_ctr' aliases to '$target_file':");
    
        $self->{_need_to_install_aliases_list} = $need_to_install_aliases_list;

        foreach my $alias_list_ref (@{$need_to_install_aliases_list}){
        
            my $alias_name = $alias_list_ref->[0];
        
            my $alias_val  = $alias_list_ref->[1];
        
            print "alias $alias_name=$alias_val\n";
        }


        $self->_prompt_user_whether_should_install();
    }

    if ($need_to_save_aliases_ctr > 0){

        $self->{_need_to_save_aliases_list} = $need_to_save_aliases_list;

        printYellow("Need to save the following '$need_to_save_aliases_ctr' aliases to '$source_file':");
    
        foreach my $alias_list_ref (@{$need_to_save_aliases_list}){
        
            my $alias_name = $alias_list_ref->[0];
        
            my $alias_val  = $alias_list_ref->[1];
        
            print "alias $alias_name=$alias_val\n";
        }

        $self->_prompt_user_whether_should_save();
    }
}


sub _prompt_user_whether_should_install {

    my $self = shift;
    

    my $answer;

    while (1){

        print "Shall I install these aliases? [Y/n/q]";
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ((!defined($answer)) || ($answer eq '')){
            $answer = 'Y';
        }
        
        if ($answer eq 'Y'){
        
            $self->_install_aliases();
        
            last;
        }        
        elsif ($answer eq 'N'){
        
            $self->{_logger}->info("User does not want to install aliases");
        
            last;
        }
        elsif ($answer eq 'Q'){
        
            $self->{_logger}->info("User wants to quit");
        
            printBoldRed("Okay, bye.");
        
            exit(1);
        }
    }
}

sub _install_aliases {

    my $self = shift;


    my $file = $self->getTargetFile();
    
    my $bakfile = $file. '.bak';

    copy($file, $bakfile) || $self->{_logger}->logconfess("Could not copy file '$file' to '$bakfile' : $!");
    

    my @lines = read_file($bakfile);

    open (OUTFILE, ">$file") || $self->{_logger}->logconfess("Could not open '$file' in write mode : $!");
    

    print OUTFILE join("", @lines);


    my $date = localtime();

    print OUTFILE "\n\n## Added aliases on $date\n";
    

    my $ctr = 0;

    foreach my $alias_list_ref (@{$self->{_need_to_install_aliases_list}}){
    
        my $alias_name = $alias_list_ref->[0];
    
        my $alias_val  = $alias_list_ref->[1];
    
        $ctr++;

        print OUTFILE "alias $alias_name=$alias_val\n";
    }


    close OUTFILE;

    $self->{_logger}->info("Wrote '$ctr' new aliases to '$file'");

    printGreen("Wrote '$ctr' new aliases to '$file'");
    
}


sub _prompt_user_whether_should_save {

    my $self = shift;
    

    my $answer;

    while (1){

        print "Shall I save these aliases? [Y/n/q]";
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ((!defined($answer)) || ($answer eq '')){
            $answer = 'Y';
        }
        
        if ($answer eq 'Y'){
        
            $self->_save_aliases();
        
            last;
        }        
        elsif ($answer eq 'N'){
        
            $self->{_logger}->info("User does not want to save aliases");
        
            last;
        }
        elsif ($answer eq 'Q'){
        
            $self->{_logger}->info("User wants to quit");
        
            printBoldRed("Okay, bye.");
        
            exit(1);
        }
    }
}


sub _save_aliases {

    my $self = shift;

    my $file = $self->getSourceFile();
    
    my $bakfile = $file. '.bak';

    copy($file, $bakfile) || $self->{_logger}->logconfess("Could not copy file '$file' to '$bakfile' : $!");
    

    my @lines = read_file($bakfile);

    open (OUTFILE, ">$file") || $self->{_logger}->logconfess("Could not open '$file' in write mode : $!");
    

    print OUTFILE join("", @lines);


    my $date = localtime();

    print OUTFILE "\n\n## Added aliases on $date\n";
    

    my $ctr = 0;

    foreach my $alias_list_ref (@{$self->{_need_to_save_aliases_list}}){
    
        my $alias_name = $alias_list_ref->[0];
    
        my $alias_val  = $alias_list_ref->[1];
    
        $ctr++;

        print OUTFILE "alias $alias_name=$alias_val\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote '$ctr' new aliases to '$file'");
    
    printGreen("Wrote '$ctr' new aliases to '$file'");
    
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
