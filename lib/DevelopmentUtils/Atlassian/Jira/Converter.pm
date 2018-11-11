package DevelopmentUtils::Atlassian::Jira::Converter;

use Moose;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Atlassian::Jira::Issue;

use constant TRUE  => 1;
use constant FALSE => 0;

## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Atlassian::Jira::Converter(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Atlassian::Jira::Converter";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

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


sub get_issue {

    my $self = shift;
    my ($lookup) = @_;

    my $issue = new DevelopmentUtils::Atlassian::Jira::Issue();
    if (!defined($issue)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Atlassian::Jira::Issue");
    }

    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");


    return $issue;
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Atlassian::Jira::Converter
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Atlassian::Jira::Converter;
 my $manager = DevelopmentUtils::Atlassian::Jira::Converter::getInstance();
 $manager->addCodeCommitComment($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
