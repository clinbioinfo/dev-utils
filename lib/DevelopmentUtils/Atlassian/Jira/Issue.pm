package DevelopmentUtils::Atlassian::Jira::Issue;

use Moose;

use DevelopmentUtils::Logger;

use constant TRUE  => 1;
use constant FALSE => 0;

has 'id' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_id',
    reader   => 'get_id',
    required => FALSE,
    );

has 'title' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_title',
    reader   => 'get_title',
    required => FALSE
    );

has 'priority' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_priority',
    reader   => 'get_priority',
    required => FALSE
    );

has 'desc' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_desc',
    reader   => 'get_desc',
    required => FALSE,
    );

has 'label_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'set_labels',
    reader   => 'get_labels',
    required => FALSE
    );

has 'component_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'set_components',
    reader   => 'get_components',
    required => FALSE
    );

has 'reporter' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'set_reporter',
    reader   => 'get_reporter',
    required => FALSE
    );

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

sub has_labels {

    my $self = shift;
    my $labels = $self->get_labels;
    if (defined($labels)){
        if (scalar(@{$labels}) > 0){
            return TRUE;
        }
    }

    return FALSE;    
}

sub has_components {

    my $self = shift;
    my $components = $self->get_components;
    if (defined($components)){
        if (scalar(@{$components}) > 0){
            return TRUE;
        }
    }

    return FALSE;    
}


sub add_labels {

    my $self = shift;
    my ($labels) = @_;

    if (!defined($labels)){
        $self->{_logger}->logconfess("labels was not defined");
    }

    my $current_labels = $self->get_labels;
    for my $label (@{labels}){
        push(@{$current_labels}, $label);
    }

    $self->set_labels($current_labels);
}

sub add_components {

    my $self = shift;
    my ($components) = @_;

    if (!defined($components)){
        $self->{_logger}->logconfess("components was not defined");
    }

    my $current_components = $self->get_components;
    for my $component (@{components}){
        push(@{$current_components}, $component);
    }

    $self->set_components($current_components);
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Atlassian::Jira::Issue
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Atlassian::Jira::Issue;
 my $issue = new DevelopmentUtils::Atlassian::Jira::Issue(
   id => $id,
   title => $title,
   desc => $description,
   priority => $priority
 );

 $issue->add_label($label);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
