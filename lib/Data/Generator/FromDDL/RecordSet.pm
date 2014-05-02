package Data::Generator::FromDDL::RecordSet;
use strict;
use warnings;
use File::Temp ();
use Storable qw(nstore retrieve);
use List::Util qw(first);
use JSON ();
use YAML::Tiny ();
use bytes ();
use Class::Accessor::Lite (
    rw => [qw(table n cols)],
);
use Data::Dumper;

use Data::Generator::FromDDL::Util qw(need_quote_data_type);

our $MAX_RECORDS_PER_STORAGE = 100_000;

sub new {
    my ($class, $table, $n) = @_;
    return bless {
        table => $table,
        n => $n,
        cols => [],
    }, $class;
}

sub add_cols {
    my ($self, $field, $values) = @_;

    # serialize and store values into multiple files for saving memory.
    my $n = $self->n;
    my $offset = 0;
    my @storages;
    while ($n > 0) {
        my $fh = File::Temp->new(UNLINK => 1);
        my $size = $n >= $MAX_RECORDS_PER_STORAGE ? $MAX_RECORDS_PER_STORAGE : $n;
        my @sliced = @$values[$offset..($offset + $size - 1)];
        nstore \@sliced, $fh->filename;
        $offset += $size;
        $n -= $size;
        push @storages, $fh;
    }

    push @{$self->{cols}}, {
        field => $field,
        storages => \@storages,
    };
}

sub get_col_values {
    my ($self, $field_name, $size, $offset) = @_;
    my $col = first { $_->{field}->name eq $field_name } @{$self->cols};
    if ($col) {
        my @values;
        my @storages = @{$col->{storages}};
        if ($size) {
            $offset ||= 0;
            while ($size > 0) {
                my $storage_no = int($offset / $MAX_RECORDS_PER_STORAGE);
                my $val = retrieve $storages[$storage_no]->filename;
                if ($size > $MAX_RECORDS_PER_STORAGE) {
                    push @values, @$val[0..($MAX_RECORDS_PER_STORAGE - 1)];
                } else {
                    push @values, @$val[0..($size - 1)];
                }
                $size -= $MAX_RECORDS_PER_STORAGE;
                $offset += $MAX_RECORDS_PER_STORAGE;
            }
        } else {
            for (@storages) {
                my $val = retrieve $_->filename;
                push @values, @$val;
            }
        }
        return wantarray ? @values : \@values;
    } else {
        return undef;
    }
}

sub _construct_rows {
    my ($self, $size, $offset, $with_quote) = @_;
    my $cols = $self->cols;
    my @rows;
    my %values = map {
        my $field_name = $_->{field}->name;
        my $values = $self->get_col_values($field_name, $size, $offset);
        $field_name => $values;
    } @$cols;

    for my $i (0 .. ($size - 1)) {
        my $row = [map {
            my $field = $_->{field};
            if ($with_quote && need_quote_data_type($field->data_type)) {
                "'" . $values{$field->name}->[$i] . "'";
            } else {
                $values{$field->name}->[$i];
            }
        } @$cols];
        push @rows, $row;
    }

    return @rows;
}

sub _construct_data {
    my $self = shift;
    my $cols = $self->cols;
    my @fields = map { $_->{field} } @$cols;
    my @rows = $self->_construct_rows;

    my $data = {
        table => $self->table->name,
        values => [],
    };
    for my $row (@rows) {
        my $record = {};
        for (0..$#fields) {
            $record->{$fields[$_]->name} = $row->[$_];
        }
        push @{$data->{values}}, $record;
    }
    return $data;
}

sub to_sql {
    my ($self, $size, $offset, $pretty, $bytes_per_sql) = @_;
    my $cols = $self->cols;
    my @fields = map { $_->{field} } @$cols;
    my @rows = $self->_construct_rows($size, $offset, 1);

    my $format;
    my $record_sep;
    if ($pretty) {
        $format = qq(
INSERT INTO
    `%s` (%s)
VALUES
    );
        $record_sep = ",\n    ";
    } else {
        $format = 'INSERT INTO `%s` (%s) VALUES ';
        $record_sep = ',';
    }
    my $columns = join ',', map { '`' . $_->name . '`' } @fields;
    my $insert_stmt = sprintf $format, $self->table->name, $columns;

    my $sqls = '';
    my @values;
    my $sum_bytes = bytes::length($insert_stmt) + 1; # +1 is for trailing semicolon of sql
    my $record_sep_len = bytes::length($record_sep);
    for my $row (@rows) {
        my $value = '(' . join(',', @$row) . ')';
        my $v_len = bytes::length($value);
        if ($sum_bytes + $v_len >= $bytes_per_sql) {
            if (@values) {
                $sqls .= $insert_stmt . (join $record_sep, @values) . ';';
                $sum_bytes = bytes::length($insert_stmt) + 1;
                @values = ();
            }
        }
        push @values, $value;
        $sum_bytes += $v_len + $record_sep_len;
    }

    if (@values) {
        $sqls .= $insert_stmt . (join $record_sep, @values) . ';';
    }
    return $sqls . "\n";
}

sub to_json {
    my ($self, $pretty) = @_;
    my $data = $self->_construct_data;
    if ($pretty) {
        return JSON->new->pretty->encode($data);
    } else {
        return JSON->new->encode($data);
    }
}

sub to_yaml {
    my ($self) = @_;
    my $data = $self->_construct_data;
    return YAML::Tiny::Dump($data);
}

1;
