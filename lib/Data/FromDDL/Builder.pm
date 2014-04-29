package Data::FromDDL::Builder;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(first);
use List::MoreUtils qw(any);
use Class::Data::Inheritable;
use Data::FromDDL::RecordSet;
use base qw(Exporter Class::Data::Inheritable);
our @EXPORT = qw(datatype);

__PACKAGE__->mk_classdata('dispatch_table', {});

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub generate {
    my ($self, $n) = @_;
    my $table = $self->{table};
    my @constraints = $table->get_constraints;
    # my $records = {};
    for my $field ($table->get_fields) {
        my @field_constraints = grep { 
            my $constraint = $_;
            any {$_->name eq $field->name } $constraint->fields;
        } @constraints;

        $self->dispatch($field->data_type);
        # my $method = _normalize_data_type($field->data_type);
        # my $cols = $self->$method($field, \@field_constraints, $others);
        # $records->{$field->name} = $cols;
    }
}

sub dispatch {
    my ($self, $data_type) = @_;
    my $class = ref $self;
    my $code = $class->dispatch_table->{$data_type};
    $code->();
}

## DSL
sub datatype($&) {
    my ($data_type, $code) = @_;
    my ($class) = caller;

    # update dispatch table
    my $dispatch_table = $class->dispatch_table;
    $dispatch_table->{$data_type} = $code;
    $class->dispatch_table($dispatch_table);
}

1;
