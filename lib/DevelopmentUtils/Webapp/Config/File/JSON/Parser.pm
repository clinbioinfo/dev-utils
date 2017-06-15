package DevelopmentUtils::Webapp::Config::File::JSON::Parser;

use Moose;
use Carp;
use JSON::Parse 'json_file_to_perl';

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

    $self->_parseFile(@_);

    $self->{_is_parsed} = FALSE;
}

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Webapp::Config::File::JSON::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Webapp::Config::File::JSON::Parser";
        }
    }

    return $instance;
}

sub getWebappInstallLookup {

    my $self = shift;

    return $self->{_projects_lookup};
}


sub _parseFile {

    my $self = shift;

    my $file = $self->getWebappConfigFile();

    if (!defined($file)){
        $self->{_logger}->logconfess("projects conf file was not defined");
    }

    if (!-e $file){
        $self->{_logger}->logconfess("project config JSON file '$file' does not exist");
    }

    my $lookup = json_file_to_perl($file);
    if (!defined($lookup)){
        $self->{_logger}->logconfess("lookup was not defined for file '$file'");
    }

    $self->{_projects_lookup} = $lookup;

    $self->{_is_parsed} = TRUE;
}


1==1; ## End of module


__END__


=head1 NAME

 DevelopmentUtils::Webapp::Config::File::JSON::Parser

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Webapp::Config::File::JSON::Parser;

 my $parser = DevelopmentUtils::Webapp::Config::File::JSON::Parser(masterConfigFile=>$file);

 my $lookup = $parser->getWebappInstallLooukp();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

 new
 _init
 DESTROY


=over 4

=cut
