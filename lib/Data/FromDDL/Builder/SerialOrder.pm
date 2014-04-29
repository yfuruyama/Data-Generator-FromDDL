package Data::FromDDL::Builder::SerialOrder;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(first);
use Carp qw(croak);
use POSIX qw(strftime);
use Data::FromDDL::Builder;
use Data::FromDDL::RecordSet;
use Data::FromDDL::Util qw(get_numeric_type_byte);
our @ISA = qw(Data::FromDDL::Builder);

sub new {
    my ($class, $args) = @_;
    bless $args, $class;
};

# TODO : support these types
# - float
# - double
# - enum

datatype 'integer' => sub {
    my ($builder, $field, $n, $constraints, $recordsets) = @_;
    my $byte = get_numeric_type_byte($field->data_type);
    my $is_unsigned = $field->extra->{unsigned} || 0;

    if (@$constraints) {
        my $constraint;
        if (scalar(@$constraints) >= 2) {
            # FOREIGN KEY 優先
            $constraint = first { uc($_->type) eq 'FOREIGN KEY' } @$constraints;
            unless ($constraint) {
                $constraint = $constraints->[0];
            }
        } else {
            $constraint = $constraints->[0];
        }
        my $c_type = uc($constraint->type);
        if ($c_type eq 'FOREIGN KEY') {
            my $ref_table_name = $constraint->reference_table;
            my @ref_fields = $constraint->reference_fields;
            my $ref_field = $ref_fields[0];
            my $recordset = first { $_->table->name eq $ref_table_name } @$recordsets;
            croak('not found')
                unless defined($recordset);

            my @values = $recordset->get_values($ref_field);
            croak("field not found: $ref_field")
                unless @values;
            my $v_size = scalar(@values);
            return [map { $values[int(rand($v_size))] } (1..$n)];
        } elsif ($c_type eq 'PRIMARY KEY' or $c_type eq 'UNIQUE KEY' or $field->is_auto_increment) {
            return [1..$n];
        }
    } else {
        if ($field->is_auto_increment) {
            return [1..$n];
        }
    }

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
    my ($builder, $field, $n, $constraints, $recordsets) = @_;
    my $field_name = $field->name;
    my $field_size = $field->size;

    my $record_prefix = substr $field_name, 0, $field_size - length($n);
    my $format = $record_prefix . "%0" . length($n) . "d";
    return [map { sprintf $format, $_ } (1..$n)];
};

1;
