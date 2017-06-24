package DevelopmentUtils::UmletClassDiagramToPerlModule::Converter;

use Moose;
use Term::ANSIColor;


use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;
use DevelopmentUtils::Umlet::File::XML::Parser;
use DevelopmentUtils::Perl::Module::File::Writer;

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

        $instance = new DevelopmentUtils::UmletClassDiagramToPerlModule::Converter(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::UmletClassDiagramToPerlModule::Converter";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->_initUmletParser(@_);

    $self->_initPerlModuleWriter(@_);

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

sub _initUmletParser {

    my $self = shift;

    my $parser = DevelopmentUtils::Umlet::File::XML::Parser::getInstance(@_);
    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Umlet::File::XML::Parser");
    }

    $self->{_parser} = $parser;
}

sub _initPerlModuleWriter {

    my $self = shift;

    my $writer = new DevelopmentUtils::Perl::Module::File::Writer(@_);
    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Perl::Module::File::Writer");
    }

    $self->{_writer} = $writer;
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



sub runConversion {

    my $self = shift;
    
    my $record_list = $self->{_parser}->getClassList();
    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

    # &parseUxfFile($infile);

    $self->{_writer}->createAPI($record_list);

    # &createAPI();

    if ($self->getVerbose()){

        print "Conversion completed.\n";

        print "See output files in directory '$self->getOutdir()'\n";
    }
}




no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::UmletClassDiagramToPerlModule::Converter
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::UmletClassDiagramToPerlModule::Converter;
 my $manager = DevelopmentUtils::UmletClassDiagramToPerlModule::Converter::getInstance();
 $manager->commitCodeAndPush($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
