package DevelopmentUtils::MongoDB::Helper::Factory;

use Moose;

use DevelopmentUtils::MongoDB::Ubuntu16_04::Helper;
use DevelopmentUtils::MongoDB::Redhat7_3::Helper;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TYPE => 'ubuntu16_04';

## Singleton support
my $instance;


has 'type' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'setType',
    reader  => 'getType'
);

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::MongoDB::Helper::Factory(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::MongoDB::Helper::Factory";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_logger}->info("Instantiated " . __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _getType {

    my $self = shift;
    my (%args) = @_;

    my $type = $self->getType();

    if (!defined($type)){

        if (( exists $args{type}) && ( defined $args{type})){
            $type = $args{type};
        }
        elsif (( exists $self->{_type}) && ( defined $self->{_type})){
            $type = $self->{_type};
        }
        else {
            $type = DEFAULT_TYPE;
            $self->{_logger}->warn("type was not defined and therefore was set to '$type'");
        }

        $self->setType($type);
    }

    return $type;
}

sub create {

    my $self = shift;

    my $type  = $self->_getType(@_);

    if (lc($type) eq 'ubuntu16_04'){

        my $helper = DevelopmentUtils::MongoDB::Ubuntu16_04::Helper::getInstance(@_);
        if (!defined($helper)){
            confess "Could not instantiate DevelopmentUtils::MongoDB::Ubuntu16_04::Helper";
        }

        return $helper;
    }
    elsif (lc($type) eq 'redhat7_3'){

        my $helper = DevelopmentUtils::MongoDB::Helper::Redhat7_3::Helper::getInstance(@_);
        if (!defined($helper)){
            confess "Could not instantiate DevelopmentUtils::MongoDB::Redhat7_3::Helper";
        }

        return $helper;
    }
    else {
        confess "type '$type' is not currently supported";
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 DevelopmentUtils::MongoDB::Helper::Factory

 A module factory for creating Helper instances.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::MongoDB::Helper::Factory;
 my $factory = DevelopmentUtils::MongoDB::Helper::Factory::getIntance();
 my $helper = $factory->create(type => 'ubuntu16_04');

=head1 AUTHOR

 Jaideep Sundaram

 sundaramj@medimmune.com

=head1 METHODS

=over 4

=cut