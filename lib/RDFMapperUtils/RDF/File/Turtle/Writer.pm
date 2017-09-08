package RDFMapperUtils::RDF::File::Turtle::Writer;

use Moose;
use Data::Dumper;

use RDFMapperUtils::Mapper::Config::File::INI::Parser;

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

my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new RDFMapperUtils::RDF::File::Turtle::Writer(@_);
        
        if (!defined($instance)){
            confess "Could not instantiate RDFMapperUtils::RDF::File::Turtle::Writer";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    # $self->_initMapperConfigFileParser(@_);

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

    my $parser = RDFMapperUtils::Mapper::Config::File::INI::Parser::getInstance(@_);
    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Mapper::Config::File::INI::Parser");
    }

    $self->{_mapper_parser} = $parser;
}


sub writeFile {

    my $self = shift;

    $self->_initMapperConfigFileParser();
    
    my $record_list = $self->getRecordList();
    if (!defined($record_list)){
        $self->{_logger}->logconfess("record_list was not defined");
    }

    my $outfile = $self->getOutfile();

    my $position_to_name_lookup = $self->getPositionToNameLookup();

    my $record_ctr = 0;

    $self->{_has_rules_ctr} = 0;
    $self->{_no_rules_ctr} = 0;


    my $outfile = $self->getOutfile();

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");


    foreach my $record (@{$record_list}){

        $record_ctr++;

        my $column_number = 0;

        foreach my $column_value (@{$record}){

            $column_number++;

            if (!exists $position_to_name_lookup->{$column_number}){
                $self->{_logger}->fatal("position_to_name_lookup:" . Dumper $position_to_name_lookup);
                $self->{_logger}->logconfess("column_number '$column_number' does not exist in the lookup");
            }

            my $column_name = $position_to_name_lookup->{$column_number};

            if ($self->{_mapper_parser}->hasRulesByColumnName($column_name)){

                print OUTFILE $column_value . "\n";

                if (!exists $self->{_column_name_to_has_rules_ctr_lookup}->{$column_name}){
                    $self->{_has_rules_ctr}++;
                    $self->{_column_name_to_has_rules_ctr_lookup}->{$column_name}++;
                }

                my $rules_record = $self->{_mapper_parser}->getRulesByColumnName($column_name);
                if (!defined($rules_record)){
                    $self->{_logger}->logconfess("rules_record was not defined for column name '$column_name' column number '$column_number");
                }

                my $isatype = $rules_record->getIsaType();
                if (defined($isatype)){
                    print OUTFILE 'is_a => ' . $isatype . "\n";
                }

                if ($rules_record->hasRelationshipList()){

                    my $list =  $rules_record->getRelationshipList();
                    if (!defined($list)){
                        $self->{_logger}->logconfess("relationship list was not defined");
                    }

                    foreach my $rel_list (@{$list}){
                        my $relationship_name = $rel_list->[0];
                        my $rel_column_number = $rel_list->[1];
                        my $rel_value = $record->[$rel_column_number];

                        print OUTFILE $relationship_name . ' => ' . $rel_value . "\n";
                    }
                }
            }
            else {

                if (!exists $self->{_column_name_to_has_no_rules_ctr_lookup}->{$column_name}){
                    $self->{_no_rules_ctr}++;
                    $self->{_column_name_to_has_no_rules_ctr_lookup}->{$column_name}++;
                }

                $self->{_logger}->info("No rules for column '$column_name' - so will ignore.");
            }
        }
    }

    $self->{_logger}->info("Processed '$record_ctr' records");

    if ($self->{_has_rules_ctr} > 0){
        $self->{_logger}->info("Encountered '$self->{_has_rules_ctr}' columns names that did have some rules");
    }

    if ($self->{_no_rules_ctr} > 0){
        $self->{_logger}->info("Encountered '$self->{_no_rules_ctr}' column names that did not have any rules");
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote records to '$outfile'");

    print "Wrote records to '$outfile'\n";

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