package DevelopmentUtils::Webapp::Config::Manager;

use Moose;
use Data::Dumper;
use Carp;

use DevelopmentUtils::Webapp::Config::File::JSON::Parser;

use constant TRUE => 1;
use constant FALSE => 0;

has 'webapp_install_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setWebappConfigFile',
    reader   => 'getWebappConfigFile',
    required => FALSE,
    );

## Singleton support
my $instance;


sub BUILD {

    my $self = shift;

    $self->_initParser(@_);
}

sub _initParser {

    my $self = shift;

    my $parser = DevelopmentUtils::Webapp::Config::File::JSON::Parser::getInstance(@_);

    if (!defined($parser)){

        confess "Could not instantiate DevelopmentUtils::Webapp::Config::File::JSON::Parser";
    }

    $self->{_parser} = $parser;
}

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Webapp::Config::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Webapp::Config::Manager";
        }
    }

    return $instance;
}

sub DESTROY  {

    my $self = shift;
}

sub getWebappInstallLookup {

    my $self = shift;
    
    return $self->{_parser}->getWebappInstallLookup();
}

1==1; ## End of module

__END__

=head1 NAME

 DevelopmentUtils::Webapp::Config::Manager

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Webapp::Config::Manager;
 my $cm = DevelopmentUtils::Webapp::Config::Manager::getInstance();
 $cm->getWebappInstallLookup();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY
 getInstance

=over 4

=cut
