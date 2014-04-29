package Data::FromDDL::Builder::SerialOrder;
use strict;
use warnings;
use Data::FromDDL::Builder;
use Data::FromDDL::RecordSet;
our @ISA = qw(Data::FromDDL::Builder);

sub new {
    my ($class, $args) = @_;
    bless $args, $class;
};

datatype 'varchar' => sub {
    my ($builder, $field, $n, $constraints, $recordsets) = @_;
    return [(1..$n)];
};

datatype 'char' => sub {
    my ($builder, $field, $n, $constraints, $recordsets) = @_;
    return [(1..$n)];
};

datatype 'int' => sub { shift->redispatch('integer', @_); };

datatype 'integer' => sub {
    # TODO
    # unsigned
    my ($builder, $field, $n, $constraints, $recordsets) = @_;
    
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
            my $g = first { $_->table->name eq $ref_table_name } @$recordsets;
            die('not found')
                unless defined($g);

            my $records = $g->records;
            die ("field not found: $ref_field")
                unless exists $records->{$ref_field};
            my $candidates = $records->{$ref_field};
            my $c_size = scalar(@$candidates);
            return [map { $candidates->[int(rand($c_size))] } (1..$n)];
        } elsif ($c_type eq 'PRIMARY KEY' or $c_type eq 'UNIQUE KEY' or $field->is_auto_increment) {
            return [1..$n];
        }
    } else {
        if ($field->is_auto_increment) {
            return [1..$n];
        }
    }

    return [map { int(rand(2 ** 32)) } (1..$n)];
    # if ($byte) {
        # return [map { int(rand(2 ** ($byte * 8))) } (1..$self->n)];
    # } else {
        # return [map { int(rand(2 ** 32)) } (1..$self->n)];
    # }
};

#TODO
#timestamp
#mediumint 3byte
#bigint 8byte
#float
#double
#tinytext
#text
#mediumtext
#enum

1;
