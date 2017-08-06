package RDFMapperUtils::File::Parser::Factory;

use Moose;

use RDFMapperUtils::File::CSV::Parser;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TYPE => 'csv';

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

        $instance = new RDFMapperUtils::File::Parser::Factory(@_);

        if (!defined($instance)){

            confess "Could not instantiate RDFMapperUtils::File::Parser::Factory";
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

    if (lc($type) eq 'csv'){

        my $parser = RDFMapperUtils::File::CSV::Parser::getInstance(@_);
        if (!defined($parser)){
            confess "Could not instantiate RDFMapperUtils::File::CSV::Parser";
        }

        return $parser;
    }
    else {
        confess "type '$type' is not currently supported";
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 RDFMapperUtils::File::Parser::Factory

 A module factory for creating File Parser instances.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::File::Parser::Factory;
 my $factory = RDFMapperUtils::File::Parser::Factory::getIntance();
 my $parser = $factory->create(type => 'csv');

=head1 AUTHOR

 Jaideep Sundaram

 sundaramj@medimmune.com

=head1 METHODS

=over 4

=cut