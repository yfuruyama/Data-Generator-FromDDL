package Data::Generator::FromDDL::RecordSet;
# Data::Generator::FromDDL::RecordSet is columnar-oriented storage.
# To output each generated record, it's needed to convert columns into rows.

use strict;
use warnings;
use POSIX qw(ceil);
use List::Util qw(first);
use Compress::Zlib qw(compress uncompress);
use bytes ();
use Class::Accessor::Lite (
    rw => [qw(table n cols)],
);

use Data::Generator::FromDDL::Util qw(need_quote_data_type);

use constant RECORDS_PER_CHUNK => 100_000;

sub new {
    my ($class, $table, $n) = @_;
    return bless {
        table => $table,
        n => $n,
        cols => [],
    }, $class;
}

sub set_column_values {
    my ($self, $field, $values) = @_;

    my $n = $self->n;
    my $offset = 0;
    my $size;
    my @chunks;
    while ($n > 0) {
        $size = $n >= RECORDS_PER_CHUNK ? RECORDS_PER_CHUNK : $n;
        my @sliced_values = @$values[$offset..($offset + $size - 1)];
        push @chunks, _store_values_into_chunk(\@sliced_values);

        $n -= $size;
        $offset += $size;
    }

    push @{$self->{cols}}, {
        field => $field,
        chunks => \@chunks,
    };
}

sub get_column_values {
    my ($self, $field_name) = @_;
    my $col = first { $_->{field}->name eq $field_name } @{$self->cols};
    if ($col) {
        return map { _fetch_values_from_chunk($_) } @{$col->{chunks}};
    } else {
        return undef;
    }
}

sub _store_values_into_chunk {
    my ($values) = @_;
    return compress(join ',', @$values);
}

sub _fetch_values_from_chunk {
    my ($chunk) = @_;
    my $joined_chunk = uncompress($chunk);
    return split ',', $joined_chunk;
}

sub iterate_through_chunks(&) {
    my ($self, $code) = @_;
    my $cols = $self->cols;
    my $num_of_chunks = ceil($self->n / RECORDS_PER_CHUNK);

    my $table = $self->table;
    my @fields = map { $_->{field} } @{$self->cols};
    for my $chunk_no (0..($num_of_chunks - 1)) {
        my @rows = $self->_construct_rows_with_chunk_no($chunk_no, 1);
        $code->($table, \@fields, \@rows);
    }
}

sub _construct_rows_with_chunk_no {
    my ($self, $chunk_no, $with_quote) = @_;
    my $n = $self->n;
    my $cols = $self->cols;
    my $chunk_size
        = ($n - ($chunk_no * RECORDS_PER_CHUNK)) >= RECORDS_PER_CHUNK
        ? RECORDS_PER_CHUNK
        : $n % RECORDS_PER_CHUNK
        ;
    my %all_columns_values
        = map {
            my $field_name = $_->{field}->name;
            my @values = _fetch_values_from_chunk($_->{chunks}->[$chunk_no]);
            $field_name => {
                need_quote => need_quote_data_type($_->{field}->data_type),
                values => \@values,
            };
        } @$cols;

    my @rows;
    for my $i (0..($chunk_size - 1)) {
        my $row = [map {
            my $field = $_->{field};
            my $need_quote = $all_columns_values{$field->name}->{need_quote};
            my $values = $all_columns_values{$field->name}->{values};
            if ($with_quote && $need_quote) {
                "'" . $values->[$i] . "'";
            } else {
                $values->[$i];
            }
        } @$cols];
        push @rows, $row;
    }

    return @rows;
}

1;
