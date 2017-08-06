package RDFMapperUtils::Manager;

use Moose;
use Cwd;
use File::Path;
use FindBin;
use File::Basename;
use Term::ANSIColor;

use RDFMapperUtils::Logger;
use RDFMapperUtils::Config::Manager;
use RDFMapperUtils::File::Parser::Factory;
use RDFMapperUtils::Mapper::Config::File::INI::Writer;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_INFILE_TYPE => 'csv';

## Singleton support
my $instance;

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
    required => FALSE
    );

has 'infile_type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfileType',
    reader   => 'getInfileType',
    required => FALSE,
    default  => DEFAULT_INFILE_TYPE
    );

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new RDFMapperUtils::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate RDFMapperUtils::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);
    
    $self->_initParserFactory(@_);

    $self->_initParser(@_);    

    $self->_initWriter(@_);

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

sub _initConfigManager {

    my $self = shift;

    my $manager = RDFMapperUtils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub _initParserFactory {

    my $self = shift;

    my $factory = RDFMapperUtils::File::Parser::Factory::getInstance(@_);

    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::File::Parser::Factory");
    }

    $self->{_parser_factory} = $factory;

    $self->{_parser_factory}->setType($self->getInfileType());
}

sub _initParser {

    my $self = shift;

    my $parser = $self->{_parser_factory}->create();

    if (!defined($parser)){
        $self->{_logger}->logconfess("parser was not defined");
    }

    $self->{_parser} = $parser;

    $self->{_parser}->setInfile($self->getInfile());
}

sub _initWriter {

    my $self = shift;

    my $factory = RDFMapperUtils::File::Writer::Factory::getInstance(@_);

    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::File::Writer::Factory");
    }


    $factory->setType($self->getOutputFileType);

    $self->{_writer_factory} = $factory;
}

sub _initWriter {

    my $self = shift;

    my $writer = new RDFMapperUtils::Mapper::Config::File::INI::Writer(@_);
    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Mapper::Config::File::INI::Writer");
    }

    $self->{_writer} = $writer;
}

sub generateMapperConfigFile {

    my $self = shift;

    my $column_names_list = $self->{_parser}->getColumnNamesList();
    if (!defined($column_names_list)){
        $self->{_logger}->logconfess("column_names_list was not defined");
    }

    $self->{_writer}->setColumnNamesList($column_names_list);

    $self->{_writer}->setInfile($self->getInfile());
    
    $self->{_writer}->writeFile();
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 RDFMapperUtils::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::Manager;
 my $manager = RDFMapperUtils::Manager::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
