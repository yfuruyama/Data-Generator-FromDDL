package Data::Generator::FromDDL::Builder::SerialOrder;
use strict;
use warnings;
use List::Util qw(first);
use Carp qw(croak);
use POSIX qw(strftime);

use Data::Generator::FromDDL::Builder;
use Data::Generator::FromDDL::RecordSet;
use Data::Generator::FromDDL::Util qw(get_numeric_type_byte);
our @ISA = qw(Data::Generator::FromDDL::Builder);


datatype 'integer' => sub {
    my ($builder, $field, $n, $recordsets) = @_;

    if ($field->is_foreign_key) {
        my $constraint = $field->foreign_key_reference;
        my $ref_table = $constraint->reference_table;
        my $recordset = first { $_->table->name eq $ref_table } @$recordsets;
        croak("Table not found: $ref_table")
            unless defined($recordset);

        my $ref_field = $constraint->reference_fields->[0];
        my @values = $recordset->get_values($ref_field);
        croak("Field not found: $ref_field in table: $ref_table")
            unless @values;
        my $v_size = scalar(@values);
        return [map { $values[int(rand($v_size))] } (1..$n)];
    } elsif ($field->is_primary_key or
             $field->is_unique or
             $field->is_auto_increment) {
        return [1..$n];
    }

    my $is_unsigned = $field->extra->{unsigned} || 0;
    my $byte = get_numeric_type_byte($field->data_type);
    if ($is_unsigned) {
        return [map { int(rand(2 ** ($byte * 8))) } (1..$n)];
    } else {
        return [map {
            [1, -1]->[int(rand(2))] * int(rand(2 ** ($byte * 8 - 1)))
        } (1..$n)];
    }
};

datatype 'bigint' => sub {
    return shift->redispatch('integer', @_);
};

datatype 'int' => sub {
    return shift->redispatch('integer', @_);
};

datatype 'mediumint' => sub {
    return shift->redispatch('integer', @_);
};

datatype 'smallint' => sub {
    return shift->redispatch('integer', @_);
};

datatype 'tinyint' => sub {
    return shift->redispatch('integer', @_);
};

datatype 'timestamp' => sub {
    my $values = shift->redispatch('integer', @_);
    return [map { 
        strftime '%Y-%m-%d %H:%M:%S', localtime(abs($_))
    } @$values];
};

datatype 'char, varchar, tinytext, text, mediumtext' => sub {
    my ($builder, $field, $n, $recordsets) = @_;
    my $field_name = $field->name;
    my $field_size = $field->size;

    my $record_prefix = substr $field_name, 0, $field_size - length($n);
    my $format = $record_prefix . "%0" . length($n) . "d";
    return [map { sprintf $format, $_ } (1..$n)];
};

datatype 'enum' => sub {
    my ($builder, $field, $n, $recordsets) = @_;
    my $list = $field->extra->{list} || [];
    my $size = scalar(@$list);
    croak("Can't select value from empty ENUM list: " . $field->name)
        if $size == 0;
    return [map { $list->[int(rand($size))] } (1..$n)];
};

# TODO : support these data types
# - float
# - double

1;
