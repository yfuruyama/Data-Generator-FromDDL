package Data::FromDDL::Builder;
use strict;
use warnings;
use Data::Dumper;
use Carp qw(croak);
use List::Util qw(first);
use List::MoreUtils qw(any);
use Class::Data::Inheritable;
use Class::Accessor::Lite (
    rw => [qw(table recordsets)],
);
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
    my $table = $self->table;
    my @constraints = $table->get_constraints;
    my $recordset = Data::FromDDL::RecordSet->new($table, $n);
    for my $field ($table->get_fields) {
        my @field_constraints = grep { 
            my $constraint = $_;
            any {$_->name eq $field->name } $constraint->fields;
        } @constraints;

        my $data_type = lc($field->data_type);
        my $values = $self->dispatch($data_type, $field, $n, \@field_constraints);
        $recordset->add_cols($field, $values);
    }
    return $recordset;
}

sub dispatch {
    my ($self, $data_type, $field, $n, $constraints) = @_;
    my $class = ref $self;
    my $code = $class->dispatch_table->{$data_type};
    croak("Unsupported data type: $data_type")
        unless $code;
    return $code->($self, $field, $n, $constraints, $self->recordsets);
}

sub redispatch {
    my ($self, $new_data_type, $field, $n, $constraints) = @_;
    return $self->dispatch($new_data_type, $field, $n, $constraints);
}

## DSL
sub datatype($&) {
    my ($data_type, $code) = @_;
    my ($class) = caller;

    # update dispatch table
    my $dispatch_table = $class->dispatch_table;
    for (split /,\s*/, $data_type) {
        $dispatch_table->{$_} = $code;
    }
    $class->dispatch_table($dispatch_table);
}

1;
