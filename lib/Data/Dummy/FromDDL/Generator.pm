package Data::Dummy::FromDDL::Generator;
use 5.008005;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(any);

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
        # my @field_constraints = grep { 
            # any {$_ -> } $_->fields;
        # } @constraints;
        my $cols = $self->$method($field, undef, $others);
        $records->{$field->name} = $cols;
    }
    $self->records($records);
}

sub to_sql_insert_clause {
    my $self = shift;
    my $table = $self->table;
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
    my $format = "-- \nINSERT INTO `%s` (%s) VALUES %s;\n\n";
    my $columns = join ',', map { $_->name } @fields;
    my $values = join ',', @rows;
    return sprintf $format, $table->name, $columns, $values;
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

sub integer {
    my ($self, $field, $constraint, $generators) = @_;
    # TODO
    # unsigned
    if ($constraint) {
        my $c_type = uc($constraint->type);
        if ($c_type eq 'PRIMARY KEY' or $field->is_auto_increment) {
            return [1..$self->n];
        } elsif ($c_type eq 'FOREIGN KEY') {
            my $ref_table = $constraint->reference_table;
        }
    } else {
        if ($field->is_auto_increment) {
            return [1..$self->n];
        }
    }

    return [map { int(rand(2 ** 32)) } (1..$self->n)];
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
