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
use RDFMapperUtils::Mapper::Config::File::INI::Parser;
use RDFMapperUtils::RDF::File::Writer::Factory;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_INFILE_TYPE => 'csv';

use constant DEFAULT_RDF_FILE_TYPE => 'turtle';

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

has 'rdf_file_type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setRDFFileType',
    reader   => 'getRDFFileType',
    required => FALSE,
    default  => DEFAULT_RDF_FILE_TYPE
    );

has 'mapper_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setMapperConfigFile',
    reader   => 'getMapperConfigFile',
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
    
    $self->_initDataFileParserFactory(@_);

    $self->_initDataFileParser(@_);    

    $self->_initMapperConfigFileParser(@_);

    $self->_initRDFFileWriterFactory(@_);

    $self->_initRDFFileWriter(@_);

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

sub _initDataFileParserFactory {

    my $self = shift;

    my $factory = RDFMapperUtils::File::Parser::Factory::getInstance(@_);

    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::File::Parser::Factory");
    }

    $self->{_data_file_parser_factory} = $factory;

    $self->{_data_file_parser_factory}->setType($self->getInfileType());
}

sub _initDataFileParser {

    my $self = shift;

    my $parser = $self->{_data_file_parser_factory}->create();

    if (!defined($parser)){
        $self->{_logger}->logconfess("parser was not defined");
    }

    $self->{_data_file_parser} = $parser;

    $self->{_data_file_parser}->setInfile($self->getInfile());
}

sub _initRDFFileWriterFactory {

    my $self = shift;

    my $factory = RDFMapperUtils::RDF::File::Writer::Factory::getInstance(@_);
    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::RDF::File::Writer::Factory");
    }

    $factory->setType($self->getRDFFileType());

    $self->{_rdf_file_writer_factory} = $factory;
}

sub _initRDFFileWriter {

    my $self = shift;

    my $writer = $self->{_rdf_file_writer_factory}->create();

    if (!defined($writer)){
        $self->{_logger}->logconfess("RDF file writer was not defined");
    }

    $writer->setInfile($self->getInfile());

    $writer->setInfileType($self->getInfileType());

    $writer->setMapperConfigFile($self->getMapperConfigFile());

    $writer->setOutfile($self->getOutfile());
    
    $self->{_rdf_file_writer} = $writer;
}


sub _initMapperConfigFileParser {

    my $self = shift;

    my $parser = RDFMapperUtils::Mapper::Config::File::INI::Parser::getInstance(@_);

    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Mapper::Config::File::INI::Parser");
    }

    $self->{_mapper_config_file_parser} = $parser;
}


sub generateRDFFile {

    my $self = shift;

    my $record_list = $self->{_data_file_parser}->getRecordList();
    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

    my $position_to_name_lookup = $self->{_data_file_parser}->getPositionToNameLookup();
    if (!defined($position_to_name_lookup)){
        $self->{_logger}->logconfess("position_to_name_lookup was not defined");
    }

    my $name_to_position_lookup = $self->{_data_file_parser}->getNameToPositionLookup();
    if (!defined($name_to_position_lookup)){
        $self->{_logger}->logconfess("name_to_position_lookup was not defined");
    }

    $self->{_rdf_file_writer}->setRecordList($record_list);

    $self->{_rdf_file_writer}->setPositionToNameLookup($position_to_name_lookup);

    $self->{_rdf_file_writer}->setNameToPositionLookup($name_to_position_lookup);
    
    $self->{_rdf_file_writer}->writeFile();
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
