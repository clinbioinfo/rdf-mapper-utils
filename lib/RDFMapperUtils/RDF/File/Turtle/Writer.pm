package RDFMapperUtils::RDF::File::Turtle::Writer;

use Moose;
use RDFMapperUtils::Mapper::Config::File::Parser;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
);

has 'record_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setRecordList',
    reader   => 'getRecordList',
    required => FALSE    
);

has 'position_to_name_lookup' => (
    is       => 'rw',
    isa      => 'HashRef',
    writer   => 'setPositionToNameLookup',
    reader   => 'getPositionToNameLookup',
    required => FALSE    
);

has 'name_to_position_lookup' => (
    is       => 'rw',
    isa      => 'HashRef',
    writer   => 'setNameToPositionLookup',
    reader   => 'getNameToPositionLookup',
    required => FALSE    
);

has 'mapper_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setMapperConfigFile',
    reader   => 'getMapperConfigFile',
    required => FALSE
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
    required => FALSE
);

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
);

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
);

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initMapperConfigFileParser(@_);

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

sub _initMapperConfigFileParser {

    my $self = shift;

    my $parser = RDFMapperUtils::Mapper::Config::File::Parser::getInstance(@_);
    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Mapper::Config::File::Parser");
    }

    $self->{_mapper_parser} = $parser;
}


sub writeFile {

    my $self = shift;

    my $record_list = $self->getRecordList();
    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

    my $outfile = $self->getOutfile();

    my $position_to_name_lookup = $self->getPositionToNameLookup();

    foreach my $record (@{$record_list}){

        my $column_number = 0;

        foreach my $column_value (@{$record}){

            my $column_name = $position_to_name_lookup->{$column_number};

            my $rules_record = $self->{_mapper_parser}->getRulesByColumnName($column_name);
            if (!defined($rules_record)){
                $self->{_logger}->logconfess("rules_record was not defined for column name '$column_name' column number '$column_number");
            }



            $column_number++;
        }
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 RDFMapperUtils::RDF::File::Turtle::Writer
 A module for writing an RDF Turtle

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::RDF::File::Turtle::Writer;
 my $writer = new RDFMapperUtils::RDF::File::Turtle::Writer(
  infile             => $infile,
  infile_type        => $infile_type,
  mapper_config_file => $mapper_config_file,
  outfile            => $outfile,
  outdir             => $outdir,
  record_list        => $record_list
  );

 $writer->writeFile();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram 2017

 Distributed under GNU General Public License

=head1 METHODS

=over 4

=cut