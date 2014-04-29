package Data::FromDDL::Builder::SerialOrder;
use strict;
use warnings;
use Data::FromDDL::Builder;
our @ISA = qw(Data::FromDDL::Builder);

sub new {
    my ($class, $args) = @_;
    bless $args, $class;
};

datatype 'varchar' => sub {
    print "varchar dispatch\n";
};

datatype 'char' => sub {
    print "char dispatch\n";
};

datatype 'int' => sub {
    print "int dispatch\n";
};

datatype 'integer' => sub {
    # my ($self, $field, $constraints, $generators, $byte) = @_;
    # TODO
    # unsigned
    
    # if (@$constraints) {
        # my $constraint;
        # if (scalar(@$constraints) >= 2) {
            # # FOREIN KEY 優先
            # $constraint = first { uc($_->type) eq 'FOREIGN KEY' } @$constraints;
            # unless ($constraint) {
                # $constraint = $constraints->[0];
            # }
        # } else {
            # $constraint = $constraints->[0];
        # }
        # my $c_type = uc($constraint->type);
        # if ($c_type eq 'FOREIGN KEY') {
            # my $ref_table_name = $constraint->reference_table;
            # my @ref_fields = $constraint->reference_fields;
            # my $ref_field = $ref_fields[0];
            # my $g = first { $_->table->name eq $ref_table_name } @$generators;
            # die('not found')
                # unless defined($g);

            # my $records = $g->records;
            # die ("field not found: $ref_field")
                # unless exists $records->{$ref_field};
            # my $candidates = $records->{$ref_field};
            # my $c_size = scalar(@$candidates);
            # return [map { $candidates->[int(rand($c_size))] } (1..$self->n)];
        # } elsif ($c_type eq 'PRIMARY KEY' or $c_type eq 'UNIQUE KEY' or $field->is_auto_increment) {
            # return [1..$self->n];
        # }
    # } else {
        # if ($field->is_auto_increment) {
            # return [1..$self->n];
        # }
    # }

    # if ($byte) {
        # return [map { int(rand(2 ** ($byte * 8))) } (1..$self->n)];
    # } else {
        # return [map { int(rand(2 ** 32)) } (1..$self->n)];
    # }
};

1;
