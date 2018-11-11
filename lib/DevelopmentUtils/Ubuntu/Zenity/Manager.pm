package DevelopmentUtils::Ubuntu::Zenity::Manager;

use Moose;

use DevelopmentUtils::Logger;

use constant TRUE  => 1;
use constant FALSE => 0;

## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Ubuntu::Zenity::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Ubuntu::Zenity::Manager";
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


sub send_info {

    my $self = shift;
    my ($content, $width, $height) = @_;

    if (!defined($content)){
        $self->{_logger}->logconfess("content was not defined");
    }

    my $cmd = "zenity --info --text '$content' --width $width --height $height";

    $self->_execute_cmd($cmd);
}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;

    $self->{_logger}->info("About to execute '$cmd'");

    eval {
        qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Ubuntu::Zenity::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Ubuntu::Zenity::Manager;
 my $manager = DevelopmentUtils::Ubuntu::Zenity::Manager::getInstance();
 $manager->addCodeCommitComment($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
