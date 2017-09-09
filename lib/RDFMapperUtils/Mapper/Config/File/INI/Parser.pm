package RDFMapperUtils::Mapper::Config::File::INI::Parser;

use Moose;
use Data::Dumper;
use Carp;
use Config::IniFiles;

use RDFMapperUtils::Mapper::Config::Rules::Record;

use constant TRUE => 1;
use constant FALSE => 0;

has 'mapper_config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setMapperConfigFile',
    reader   => 'getMapperConfigFile',
    required => TRUE
);


## Singleton support
my $instance;

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_is_parsed} = FALSE;

    $self->_parseFile();
}

sub getInstance {

    if (!defined($instance)){

        $instance = new RDFMapperUtils::Mapper::Config::File::INI::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate RDFMapperUtils::Mapper::Config::File::INI::Parser";
        }
    }

    return $instance;
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _isParsed {

    my $self = shift;

    return $self->{_is_parsed};
}

sub _getValue {

    my $self = shift;
    my ($section, $parameter) = @_;

    if (! $self->_isParsed(@_)){

        $self->_parseFile(@_);
    }

    my $value = $self->{_cfg}->val($section, $parameter);

    if ((defined($value)) && ($value ne '')){
        return $value;
    }
    else {
        return undef;
    }
}

sub _parseFile {

    my $self = shift;

    my $file = $self->getMapperConfigFile();
    if (!defined($file)){
        $self->{_logger}->logconfess("mapper config file was not defined");
    }

    if (!-e $file){
        $self->{_logger}->logconfess("file '$file' does not exist");
    }

    my $cfg = new Config::IniFiles(-file => $file);
    if (!defined($cfg)){
        $self->{_logger}->logconfess("Could not instantiate Config::IniFiles for mapping config file '$file'.  Please make sure the configuration INI file is formatted properly");
    }

    $self->{_cfg} = $cfg;

    $self->_create_rules_records();

    $self->{_is_parsed} = TRUE;
}

sub _create_rules_records {

    my $self = shift;

    my @sections = $self->{_cfg}->Sections();
    
    foreach my $section (@sections){

        if ($section eq 'file_to_rdf'){
            next;
        }

        my $record = new RDFMapperUtils::Mapper::Config::Rules::Record(column_name => $section);
        if (!defined($record)){
            $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Mapper::Config::Rules::Record for column name '$section'");
        }

        $self->{_column_name_to_record_lookup}->{$section} = $record;

        my @parameters = $self->{_cfg}->Parameters($section);

        foreach my $parameter (@parameters){

            if ($self->{_cfg}->exists($section, $parameter)){

                my $value = $self->{_cfg}->val($section, $parameter);
                if (!defined($value)){
                    $self->{_logger}->logconfess("val was not defined for section '$section' parameter '$parameter'");
                }

                if ($parameter eq 'isa_type'){
                    $record->setIsaType($value);
                }
                elsif ($parameter eq 'transform'){
                    $record->setTransform($value);
                }
                else {
                    $record->addRelationship($parameter, $value);
                }                                   
            }
        }
    }
}

sub hasRulesByColumnName {

    my $self = shift;
    my ($column_name) = @_;

    if (!defined($column_name)){
        $self->{_logger}->logconfess("column_name was not defined");
    }

    if (exists $self->{_column_name_to_record_lookup}->{$column_name}){
        return TRUE;
    }

    return FALSE;
}

sub getRulesByColumnName {
    my $self = shift;
    my ($column_name) = @_;

    if (!defined($column_name)){
        $self->{_logger}->logconfess("column_name was not defined");
    }

    if (exists $self->{_column_name_to_record_lookup}->{$column_name}){
        return $self->{_column_name_to_record_lookup}->{$column_name};
    }
    else {
        $self->{_logger}->fatal("column_name_to_record_lookup:" . Dumper $self->{_column_name_to_record_lookup});
        $self->{_logger}->logconfess("column name '$column_name' does not exist in the column name to rules record lookup");
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

 RDFMapperUtils::Mapper::Config::File::INI::Parser
 A module for parsing the mapper config INI file

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::Mapper::Config::File::INI::Parser;
 my $parser = RDFMapperUtils::Mapper::Config::File::INI::Parser(mapper_config_file => $file);
 my $rules = $parser->getRulesByColumnName($column_name);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram 2017

=head1 METHODS

=over 4

=cut