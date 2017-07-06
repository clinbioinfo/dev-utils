package DevelopmentUtils::MongoDB::Redhat7_3::Helper;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

extends 'DevelopmentUtils::MongoDB::Helper';

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

# use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();
use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::MongoDB::Redhat7_3::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::MongoDB::Redhat7_3::Helper";
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

sub _check_if_installed {

    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub _install_mongodb {

    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub _enable_auto_start {

    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub _check_service_status {
    
    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}
 
sub _start_service {

    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}

sub _stop_service {

    my $self = shift;
    # my ($) = @_;
    $self->{_logger}->logconfess("NOT YET IMPLEMENTED");
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::MongoDB::Redhat7_3::Helper

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::MongoDB::Redhat7_3::Helper;
 my $manager = DevelopmentUtils::MongoDB::Redhat7_3::Helper::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut