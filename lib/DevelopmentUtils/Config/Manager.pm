package DevelopmentUtils::Config::Manager;

use Moose;
use Data::Dumper;
use Carp;

use DevelopmentUtils::Config::File::INI::Parser;

use constant TRUE => 1;
use constant FALSE => 0;

has 'configFile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigFile',
    reader   => 'getConfigFile',
    init_arg => 'config_file'
    );

## Singleton support
my $instance;


sub BUILD {

    my $self = shift;

    $self->_initParser(@_);
}

sub _initParser {

    my $self = shift;

    my $parser = DevelopmentUtils::Config::File::INI::Parser::getInstance(@_);

    if (!defined($parser)){

        confess "Could not instantiate DevelopmentUtils::Config::File::INI::Parser";
    }

    $self->{_parser} = $parser;
}

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Config::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Config::Manager";
        }
    }

    return $instance;
}

sub DESTROY  {

    my $self = shift;
}

sub getAdminEmail {

    my $self = shift;
    return $self->{_parser}->getAdminEmail(@_);
}

sub getAdminEmailAddress {

    my $self = shift;
    return $self->getAdminEmailAddresses(@_);
}

sub getAdminEmailAddresses {

    my $self = shift;
    return $self->{_parser}->getAdminEmailAddresses(@_);
}

sub getOutdir {

    my $self = shift;

    return $self->{_parser}->getOutdir(@_);
}

sub getOutfile {

    my $self = shift;

    return $self->{_parser}->getOutfile(@_);
}


sub getLogFile {

    my $self = shift;

    return $self->{_parser}->getLogFile(@_);
}

sub getLogLevel {

    my $self = shift;

    return $self->{_parser}->getLogLevel(@_);
}

sub getJiraIssueRESTURL {

    my $self = shift;

    return $self->{_parser}->getJiraIssueRESTURL(@_);
}

sub getJiraUsername {

    my $self = shift;

    return $self->{_parser}->getJiraUsername(@_);
}

sub getJiraPassword {

    my $self = shift;

    return $self->{_parser}->getJiraPassword(@_);
}

sub getJIRABaseURL {

    my $self = shift;

    return $self->{_parser}->getJIRABaseURL(@_);
}

sub getGitProjectsLookupFile {

    my $self = shift;

    return $self->{_parser}->getGitProjectsLookupFile(@_);
}

1==1; ## End of module

__END__

=head1 NAME

 DevelopmentUtils::Config::Manager

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Config::Manager;
 my $cm = DevelopmentUtils::Config::Manager::getInstance();
 $cm->getAdminEmail();

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
