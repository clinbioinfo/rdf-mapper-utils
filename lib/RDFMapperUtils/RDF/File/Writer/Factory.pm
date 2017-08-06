package RDFMapperUtils::RDF::File::Writer::Factory;

use Moose;

use RDFMapperUtils::RDF::File::Turtle::Writer;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TYPE => 'turtle';

## Singleton support
my $instance;

has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setType',
    reader   => 'getType',
    required => FALSE,
    default  => DEFAULT_TYPE
);

sub getInstance {

    if (!defined($instance)){

        $instance = new RDFMapperUtils::RDF::File::Writer::Factory(@_);

        if (!defined($instance)){

            confess "Could not instantiate RDFMapperUtils::RDF::File::Writer::Factory";
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


sub create {

    my $self = shift;
    my ($type) = @_;

    if (!defined($type)){
        $type  = $self->getType();
    }

    if (lc($type) eq 'turtle'){

        my $writer = RDFMapperUtils::RDF::File::Turtle::Writer::getInstance(@_);
        if (!defined($writer)){
            confess "Could not instantiate RDFMapperUtils::RDF::File::Turtle::Writer";
        }

        return $writer;
    }
    else {
        confess "type '$type' is not currently supported";
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 RDFMapperUtils::RDF::File::Writer::Factory

 A module factory for creating RDF File Writer instances.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::RDF::File::Writer::Factory;
 my $factory = RDFMapperUtils::RDF::File::Writer::Factory::getIntance();
 my $writer = $factory->create(type => 'turtle');

=head1 AUTHOR

 Jaideep Sundaram

 sundaramj@medimmune.com

=head1 METHODS

=over 4

=cut