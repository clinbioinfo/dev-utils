package DevelopmentUtils::Friday::Manager;

use Moose;
use Cwd;
use Term::ANSIColor;
use Term::ANSIScreen qw(cls);

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;

use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => FALSE;

use constant DEFAULT_USERNAME =>  getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

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

        $instance = new DevelopmentUtils::Friday::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Friday::Manager";
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

sub run {

    my $self = shift;
 
    $self->_display_main_menu();
}

sub _display_main_menu {

    my $self = shift;
    
    $self->{_lookup} = {
        'Aliases' => [
            ['Check aliases', 'util/aliases_checker.pl']
            ],
        'Apache'  => [
            ['Check Apache error log file', 'util/apache_error_log_analyzer.pl']
            ],
        'Misc' => [
            ['Delete files', 'util/delete_files.pl'],
            ['Execute end-of-day util', 'util/end_of_day.pl'],
            ['Project archive stasher', 'util/project_archive_stasher.pl'],
            ],
        'Git' => [
            ['Checkout', 'util/git_checkout.pl'],
            ['Commit and add comment to JIRA', 'util/git_commit_and_update_jira.pl'],
            ['Commit only' , 'util/git_commit.pl'],
            ['Create next build tag', 'util/git_create_next_build_tag.pl'],
            ['Determine commit hash', 'util/git_determine_commit_hash_url.pl'],
            ['Determine current development branches', 'util/git_determine_current_branches.pl'],
            ['Determine current tags', 'util/git_determine_current_tags.pl'],
            ['Determine next build tag', 'util/git_determine_next_build_tag.pl'],
            ['Determine next development branch', 'util/git_determine_next_dev_branch.pl'],
            ['Archive project', 'util/git_project_archiver.pl'],
            ['Remove project' , 'util/git_project_remover.pl'],
            ['Inspect projects', 'util/git_projects_inspector.pl'],
            ],
        'Logfile' => [
            ['Logfile viewer','util/logfile_viewer.pl']
            ],
        'Perl' => [
            ['Perlbrew helper', 'util/perlbrew_helper.pl'],
            ['Compare module files','util/perl_compare_module_files.pl'],
            ['Syntax checker', 'util/perl_module_syntax_checker.pl'],
            ['Determine which modules use a particular module','util/perl_module_users.pl'],
            ],
        'SCP' => [
            ['scp assets by list file', 'util/scp_assets_by_list_file.pl'],
            ['scp assets', 'util/scp_assets.pl'],
            ],
        'Selenium' => [
            ['Selenium remote webdriver installer' ,'util/selenium_remote_webdriver_installer.pl'],
            ],
        'SSH' => [
            ['util', 'util/ssh_util.pl']
            ],
        'Sublime' => [
            ['check for uninstalled and installed snippets', 'util/sublime_snippets_checker.pl'],
            ['install snippets', 'util/sublime_snippets_installer.pl']
            ],
        'Webapp' => [
            ['Install checker', 'util/webapp_install_checker.pl'],
            ['Analyze last session instance directory','util/webapp_last_session_instance_analyzer.pl'],
            ['Determine last install instance','util/webapp_latest_install_instance_finder.pl']
            ]
        };



    my $option_lookup = {};

    my $option_ctr = 0;

    cls();

    print "\n";

    foreach my $category (sort keys %{$self->{_lookup}}){

        $option_ctr++;
        
        print $option_ctr . '. ' . $category . "\n";

        $option_lookup->{$option_ctr} = $category;
    }

    my $try_ctr = 0;

    my $answer;


    while (1){

        print "\nPlease choose an option : ";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }

        if ($try_ctr > 3){
            printBoldRed("You have issues.");
            exit(1);
        }

        $try_ctr++;
    }

    my $category = $option_lookup->{$answer};

    $self->_display_category_menu($category);
}

sub _display_category_menu {

    my $self = shift;
    my ($category) = @_;


    my $option_lookup = {};
    my $ctr = 0;

    cls();

    print "\n\nHere are the options for category '$category':\n\n";

    foreach my $item_array (@{$self->{_lookup}->{$category}}){

        $ctr++;
 
        print $ctr . '. ' . $item_array->[0] . "\n";

        $option_lookup->{$ctr} = $item_array;
    }


    my $try_ctr = 0;

    my $answer;

    while (1){


        print "Please select an option\n\n";

        $answer = <STDIN>;

        chomp $answer;

        if (exists $option_lookup->{$answer}){
            last;
        }    

        if ($try_ctr > 3){
            printBoldRed("You have issues.");
            exit(1);
        }

        $try_ctr++;
    }


    my $item_array = $option_lookup->{$answer};
    my $command = $item_array->[1];
    print "Just execute the following:\n";
    print "perl $command\n";
    exit(0);

    # $self->_display_main_menu();
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

sub printBrightBlue {

    my ($msg) = @_;
    print color 'bright_blue';
    print $msg . "\n";
    print color 'reset';
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

 DevelopmentUtils::Friday::Manager
 A module for managing perlbrew actions and activities.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Friday::Manager;
 my $manager = DevelopmentUtils::Friday::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut