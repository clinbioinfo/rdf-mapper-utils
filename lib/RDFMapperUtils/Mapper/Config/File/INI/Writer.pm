package RDFMapperUtils::Mapper::Config::File::INI::Writer;

use Moose;

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

has 'column_names_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setColumnNamesList',
    reader   => 'getColumnNamesList',
    required => FALSE    
);

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
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

sub writeFile {

    my $self = shift;

    my $list = $self->getColumnNamesList();

    my $outfile = $self->getOutfile();

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");

    print OUTFILE ";;----------------------------------------------------------------\n";
    print OUTFILE ";;\n";
    print OUTFILE ";; method-created: " . File::Spec->rel2abs($0) . "\n";
    print OUTFILE ";; date-created: " . localtime() . "\n";
    print OUTFILE ";; infile: " . $self->getInfile() . "\n";
    print OUTFILE ";;\n";
    print OUTFILE ";;----------------------------------------------------------------\n";
    print OUTFILE ";;\n";
    print OUTFILE ";;\n";
    print OUTFILE ";; Uncomment the next two lines to specify the command-line executable and\n";
    print OUTFILE ";; proper invocation if you would like the file_to_rdf.pl program to\n";
    print OUTFILE ";; invoke some other program e.g.: for loading and/or QC.\n";
    print OUTFILE ";;[file_to_rdf]\n";
    print OUTFILE ";;post-execution='your invocation command here'\n\n";    

    foreach my $name (@{$list}){

        print OUTFILE "\n[$name]\n";
        print OUTFILE ";; Uncomment next line if you wish to transform the name of this column during mapping process.\n";
        print OUTFILE ";;transform='your value here'\n";
        print OUTFILE ";; Next, using a comma-separated list- specify the type to assign to the values in this column.\n";
        print OUTFILE "isa=\n";
        print OUTFILE ";; Next, specify the relationship and the corresponding column name e.g.: relationship-type=column-name. You can insert as many as needed.\n";
        print OUTFILE "'your-relationship-1'='your-column-1'\n";
        print OUTFILE "'your-relationship-2'='your-column-2'\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote the mapper configuration template file to '$outfile'");

    print "Wrote the mapper configuration template file to '$outfile'\n";
    print "Please edit the file with appropriate mapping directives and then run the ./bin/file_to_rdf.pl mapper program.\n";
}

sub _parse_file {

    my $self = shift;

    my $infile = $self->getInfile();

    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or $self->{_logger}->logconfess("Cannot use CSV: ".Text::CSV->error_diag ());
    
    open my $fh, "<:encoding(utf8)", $infile or $self->{_logger}->logconfess("Could not open file '$infile' in read mode : $!");

    my $lineCtr = 0;
   
    while ( my $row = $csv->getline( $fh ) ) {

        $lineCtr++;

        if ($lineCtr == 1){
            $self->_parse_header_row($row);
            last;
        }
    }

    $csv->eof or $csv->error_diag();

    close $fh;

    $self->{_logger}->info("Processed '$lineCtr' in file '$infile'");
}

sub _parse_header_row {

    my $self = shift;
    my ($row) = @_;

    my $unique_lookup = {};
    my $unique_ctr = 0;
    my $field_ctr = 0;

    foreach my $column_name (@{$row}){

        $field_ctr++;

        if (! exists $unique_lookup->{$column_name}){
            $unique_ctr++;
            $unique_lookup->{$column_name}++;
            push(@{$self->{_column_names_list}}, $column_name);
        }
    }

    if ($field_ctr != $unique_ctr){
        $self->{_logger}->logconfess("Nubmer of unique column names was '$unique_ctr' and number of fields was '$field_ctr'");
    }

    $self->{_logger}->info("Finished processing the column header section");
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 RDFMapperUtils::Mapper::Config::File::INI::Writer
 A module for parsing CSV files

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::Mapper::Config::File::INI::Writer;
 my $parser = new RDFMapperUtils::Mapper::Config::File::INI::Writer(infile => $infile);
 $parser->getColumnNamesList();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram 2017

 Distributed under GNU General Public License

=head1 METHODS

=over 4

=cut