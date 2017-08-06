package RDFMapperUtils::File::CSV::Parser;

use Moose;
use Text::CSV;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

has 'verbose' => (
    is      => 'rw',
    isa     => 'Bool',
    writer  => 'setVerbose',
    reader  => 'getVerbose',
    default => DEFAULT_VERBOSE
);

has 'infile' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setInfile',
    reader => 'getInfile'    
);

has 'indir' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setIndir',
    reader => 'getIndir' 
);

my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new RDFMapperUtils::File::CSV::Parser(@_);
        
        if (!defined($instance)){
            confess "Could not instantiate RDFMapperUtils::File::CSV::Parser";
        }
    }

    return $instance;
}

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

sub getColumnNamesList {

    my $self = shift;

    if (! exists $self->{_column_names_list}){
        $self->_parse_file(@_);
    }

    $self->{_column_names_list};
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

 RDFMapperUtils::File::CSV::Parser
 A module for parsing CSV files

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::File::CSV::Parser;
 my $parser = new RDFMapperUtils::File::CSV::Parser(infile => $infile);
 $parser->getColumnNamesList();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram 2017

 Distributed under GNU General Public License

=head1 METHODS

=over 4

=cut