package RDFMapperUtils::Interactive::Helper;

use Moose;
use Cwd;
use File::Path;
use FindBin;
use File::Basename;
use Term::ANSIColor;

use RDFMapperUtils::Logger;
use RDFMapperUtils::Config::Manager;
use RDFMapperUtils::ConfigFileGenerator;
use RDFMapperUtils::Manager;

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

        $instance = new RDFMapperUtils::Interactive::Helper(@_);

        if (!defined($instance)){

            confess "Could not instantiate RDFMapperUtils::Interactive::Helper";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);
    
    # $self->_initDataFileParserFactory(@_);

    # $self->_initDataFileParser(@_);    

    # $self->_initMapperConfigFileParser(@_);

    # $self->_initRDFFileWriterFactory(@_);

    # $self->_initRDFFileWriter(@_);

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

sub run {

    my $self = shift;
    $self->_prompt_user_initial();
}

##-------------------------------------------------------
##
## Generate mapper configuration file methods
##
##-------------------------------------------------------

sub _display_overview_of_generate_mapper_config_file_step {

    my $self = shift;
    
    print "\n\nHere are the steps\n";
    print "1. step 1\n";
    print "2. step 2\n";
    print "3. step 3\n";

    $self->_generate_mapper_config_file();
}


sub _prompt_user_for_infile {

    my $self = shift;

    print "\nPlease paste the path to the input .csv file\n";
        
    my $file = <STDIN>;
        
    chomp $file;

    $file =~ s/^\s+//;
    $file =~ s/^\s+$//;

    if (!-e $file){
        printBoldRed("file '$file' does not exist");
    }

    if (!-f $file){
        printBoldRed("'$file' is not a regular file");
    }

    return $file;
}


sub _run_generate_mapper_config_file_step {

    my $self = shift;
    
    my $infile = $self->getInfile();

    if (!defined($infile)){
        $infile = $self->_prompt_user_for_infile();
    }


    my $infile_type;

    if ($infile =~ /\.csv$/){
        $infile_type = 'csv';

    }
    else {
        printBoldRed("Currently only support files with extension .csv");

        $self->_prompt_user();
    }

    my $generator = RDFMapperUtils::ConfigFileGenerator::getInstance(
        outdir               => $self->getOutdir(),
        outfile              => $self->getOutfile(),
        verbose              => $self->getVerbose(),
        infile               => $infile,
        infile_type          => $infile_type
        );

    if (!defined($generator)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::ConfigFileGenerator");
    }
        
    $generator->generateMapperConfigFile();

    $self->_prompt_user();
}

sub _generate_mapper_config_file {

    my $self = shift;
 
    # $self->_displaySectionName("Generate mapper config file");

    my $section_name = 'Generate mapper config file';

    my $options_lookup = {
        'See overview of this step' => \&_display_overview_of_generate_mapper_config_file_step,
        'Run this step' => \&_run_generate_mapper_config_file_step
    };

    $self->{_current_options_lookup} = $options_lookup;

    $self->_prompt_user($options_lookup, $section_name);
}


##-------------------------------------------------------
##
## Map CSV file to RDF methods
##
##-------------------------------------------------------

sub _display_overview_of_map_csv_file_to_rdf_step {

    my $self = shift;
    
    print "\n\nHere are the steps\n";
    print "1. step 1\n";
    print "2. step 2\n";
    print "3. step 3\n";

    $self->_map_csv_file_to_rdf();
}


sub _prompt_user_for_mapper_config_file {

    my $self = shift;

    print "\nPlease paste the path to the input mapper config .ini file\n";
        
    my $file = <STDIN>;
        
    chomp $file;

    $file =~ s/^\s+//;
    $file =~ s/^\s+$//;

    if (!-e $file){
        printBoldRed("file '$file' does not exist");
    }

    if (!-f $file){
        printBoldRed("'$file' is not a regular file");
    }

    return $file;
}


sub _run_map_csv_file_to_rdf_step {

    my $self = shift;
    
    my $infile = $self->getInfile();

    if (!defined($infile)){
        $infile = $self->_prompt_user_for_infile();
    }

    my $infile_type;

    if ($infile =~ /\.csv$/){
        $infile_type = 'csv';

    }
    else {
        printBoldRed("Currently only support files with extension .csv");

        $self->_prompt_user();
    }

    my $mapper_config_file = $self->getMapperConfigFile();

    if (!defined($mapper_config_file)){
        $mapper_config_file = $self->_prompt_user_for_mapper_config_file();
    }


    my $manager = RDFMapperUtils::Manager::getInstance(
        mapper_config_file   => $mapper_config_file,
        outdir               => $self->getOutdir(),
        outfile              => $self->getOutfile(),
        verbose              => $self->getVerbose(),
        infile               => $infile,
        infile_type          => $infile_type,
        );

    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate RDFMapperUtils::Manager");
    }
        
    $manager->generateRDFFile();

    $self->_prompt_user();
}

sub _map_csv_file_to_rdf {

    my $self = shift;
    
    my $section_name = 'Map CSV file to RDF';

    my $options_lookup = {
        'See overview of this step' => \&_display_overview_of_map_csv_file_to_rdf_step,
        'Run this step' => \&_run_map_csv_file_to_rdf_step
    };

    $self->{_current_options_lookup} = $options_lookup;

    $self->_prompt_user($options_lookup, $section_name);
}


sub _prompt_user_initial {

    my $self = shift;
    
    my $section_name = 'Main menu';

    my $options_lookup = {
        'Generate mapper configuration INI file' => \&_generate_mapper_config_file,
        'Map CSV file contents to RDF' => \&_map_csv_file_to_rdf
    };

    $self->{_main_options_lookup} = $options_lookup;

    $self->_prompt_user($options_lookup, $section_name);
}

sub _prompt_user {

    my $self = shift;
    my ($options_lookup, $section_name) = @_;

    if (!defined($options_lookup)){
        $options_lookup = $self->{_main_options_lookup};
    }

    if (!defined($section_name)){
        $section_name = 'Main menu';
    }

    $self->_displaySectionName($section_name);

    my $answer;

    print "\n\nWhat would you like to do, huh?\n";

    my $ctr = 0;
    
    my $options_ctr_lookup = {};

    foreach my $option (sort keys %{$options_lookup}){
        
        $ctr++;
        
        print $ctr . '. ' . $option . "\n";

        $options_ctr_lookup->{$ctr} = $option;
    }

    my $min = 1;
    my $max = $ctr;

    while (1){

        print "\nPlease choose an option [$min-$max/m(ain/q(uit)]";
        
        $answer = <STDIN>;
        
        chomp $answer;
        
        $answer = uc($answer);
        
        if ($answer eq 'Q'){
        
            $self->{_logger}->info("User wants to quit");
        
            printBoldRed("Okay, bye.");
        
            exit(1);
        }

        if ($answer eq 'M'){
        
            $self->_prompt_user(); 
        }

        if (exists $options_ctr_lookup->{$answer}){
        
            my $option = $options_ctr_lookup->{$answer};

            my $method = $options_lookup->{$option};

            &{$method}($self);
        }        
        else {
            printBoldRed("Not a valid option");
            next;
        }
    }
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


sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub _displaySectionName {

    my $self = shift;
    my ($msg) = @_;
    
    print color 'bold blue';
    print "*-------------------------------------------------\n";
    print "*\n";
    print "*  " . $msg . "\n";
    print "*\n";
    print "*-------------------------------------------------\n";
    print color 'reset';
}



no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 RDFMapperUtils::Interactive::Helper
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::Interactive::Helper;
 my $manager = RDFMapperUtils::Interactive::Helper::getInstance();
 $manager->run();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
