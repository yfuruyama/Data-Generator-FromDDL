package Data::Generator::FromDDL::Builder;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(first);
use List::MoreUtils qw(any);

sub new {
    my ($class, $table) = @_;
    return bless {
        table => $table,
        records => {},
    }, $class;
}

sub generate {
    my ($self, $n, $others) = @_;
    $self->n($n);
    my $table = $self->table;
    my @constraints = $table->get_constraints;
    my $records = {};
    for my $field ($table->get_fields) {
        my $method = _normalize_data_type($field->data_type);
        my @field_constraints = grep { 
            my $constraint = $_;
            any {$_->name eq $field->name } $constraint->fields;
        } @constraints;
        my $cols = $self->$method($field, \@field_constraints, $others);
        $records->{$field->name} = $cols;
    }
    $self->records($records);
}

# SQLのINSERT INTOはANSIで標準化されているものを出す
sub to_sql_insert_clause {
    my $self = shift;
    my $table = $self->table;
    my $table_name = $table->name;
    my @fields = $table->get_fields;
    my $records = $self->records;
    my @rows;
    for my $i (0..($self->n)-1) {
        my $row = join ',', map { 
            if (_is_string_type($_->data_type)) {
                "'" . $records->{$_->name}->[$i] . "'";
            } else {
                $records->{$_->name}->[$i];
            }
        } @fields;
        push @rows, "($row)";
    }
    my $format = "-- $table_name\nINSERT INTO `%s` (%s) VALUES %s;\n\n";
    my $columns = join ',', map { $_->name } @fields;
    my $values = join ',', @rows;
    return sprintf $format, $table_name, $columns, $values;
}

sub _is_string_type {
    my $type = lc(shift);
    if ($type eq 'char' or $type eq 'varchar') {
        return 1;
    } else {
        return undef;
    }
}

sub _normalize_data_type {
    my $type = shift;
    $type = lc($type);
    if ($type eq 'int') {
        $type = 'integer';
    }
    return $type;
}

sub table {
    my $self = shift;
    if (@_) {
        $self->{table} = shift;
    }
    return $self->{table};
}

sub records {
    my $self = shift;
    if (@_) {
        $self->{records} = shift;
    }
    return $self->{records};
    # return wantarray ? @{$self->{records}} : $self->{records};
}

sub n {
    my $self = shift;
    if (@_) {
        $self->{n} = shift;
    }
    return $self->{n};
}

# sub int {
    # shift->integer(@_);
# }

# datatype 'integer' => sub {
# };
# sub integer

sub integer {
    my ($self, $field, $constraints, $generators, $byte) = @_;
    # TODO
    # unsigned
    if (@$constraints) {
        my $constraint;
        if (scalar(@$constraints) >= 2) {
            # FOREIN KEY 優先
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
            my $g = first { $_->table->name eq $ref_table_name } @$generators;
            die('not found')
                unless defined($g);

            my $records = $g->records;
            die ("field not found: $ref_field")
                unless exists $records->{$ref_field};
            my $candidates = $records->{$ref_field};
            my $c_size = scalar(@$candidates);
            return [map { $candidates->[int(rand($c_size))] } (1..$self->n)];
        } elsif ($c_type eq 'PRIMARY KEY' or $c_type eq 'UNIQUE KEY' or $field->is_auto_increment) {
            return [1..$self->n];
        }
    } else {
        if ($field->is_auto_increment) {
            return [1..$self->n];
        }
    }

    if ($byte) {
        return [map { int(rand(2 ** ($byte * 8))) } (1..$self->n)];
    } else {
        return [map { int(rand(2 ** 32)) } (1..$self->n)];
    }
}

sub smallint {
    return shift->integer(@_, 2);
}

sub tinyint {
    return shift->integer(@_, 1);
}

sub char {
    return shift->varchar(@_);
}

sub varchar {
    my ($self, $field) = @_;
    my $field_name = $field->name;
    my $field_size = $field->size;

    my $record_prefix = substr $field_name, 0, $field_size - length($self->n);
    my $format = $record_prefix . "%0" . length($self->n) . "d";
    return [map { sprintf $format, $_ } (1..$self->n)];
}

1;
