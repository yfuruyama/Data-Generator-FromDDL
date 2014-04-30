package Data::Generator::FromDDL::Builder;
use strict;
use warnings;
use Carp qw(croak);
use List::Util qw(first);
use List::MoreUtils qw(any);
use Class::Data::Inheritable;
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(table recordsets)],
);
use base qw(Exporter Class::Data::Inheritable);

use Data::Generator::FromDDL::RecordSet;

our @EXPORT = qw(datatype);

__PACKAGE__->mk_classdata('dispatch_table', {});


sub generate {
    my ($self, $n) = @_;
    my $table = $self->table;
    my $recordset = Data::Generator::FromDDL::RecordSet->new($table, $n);
    for my $field ($table->get_fields) {
        my $data_type = lc($field->data_type);
        my $values = $self->dispatch($data_type, $field, $n);
        $recordset->add_cols($field, $values);
    }
    return $recordset;
}

sub dispatch {
    my ($self, $data_type, $field, $n) = @_;
    my $class = ref $self;
    my $code = $class->dispatch_table->{$data_type};
    croak("Unsupported data type: $data_type")
        unless $code;
    return $code->($self, $field, $n, $self->recordsets);
}

sub redispatch {
    my ($self, $new_data_type, $field, $n) = @_;
    return $self->dispatch($new_data_type, $field, $n);
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
