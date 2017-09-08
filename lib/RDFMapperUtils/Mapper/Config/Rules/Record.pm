package RDFMapperUtils::Mapper::Config::Rules::Record;

use Moose;

use constant TRUE => 1;
use constant FALSE => 0;

has 'column_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setColumnName',
    reader   => 'getColumnName',
    required => TRUE
);

has 'transform' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTransform',
    reader   => 'getTransform',
    required => FALSE
);

has 'isa_type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIsaType',
    reader   => 'getIsaType',
    required => FALSE
);

sub BUILD {

    my $self = shift;
}

sub addRelationship {

    my $self = shift;
    my ($relationship_type, $column_name) = @_;

    if (!defined($relationship_type)){
        $self->{_logger}->logconfess("relationship_type was not defined");
    }

    if (!defined($column_name)){
        $self->{_logger}->logconfess("column_name was not defined");
    }

    push(@{$self->{_relationship_list}}, [$relationship_type, $column_name]);
}

sub hasRelationshipList {

    my $self = shift;

    if (exists $self->{_relationship_list}){
        return TRUE;
    }

    return FALSE;
}

sub getRelationshipList {

    my $self = shift;

    return $self->{_relationship_list};
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 RDFMapperUtils::Mapper::Config::Rules::Record
 A module encapsulating each mapper rule specified in the mapper config file.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use RDFMapperUtils::Mapper::Config::Rules::Record;
 my $record = RDFMapperUtils::Mapper::Config::Rules::Record(
  column_name => $column_name,
  transform   => $transform,
  isa_type    => $isa_type,
  );

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram 2017

=head1 METHODS

=over 4

=cut