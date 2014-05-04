package Data::Generator::FromDDL::Formatter;

use strict;
use warnings;
use JSON ();
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(format pretty bytes_per_sql)],
);

sub to_string {
    my ($self, $table, $fields, $rows) = @_;
    if ($self->format =~ /json/i) {
        $self->to_json($table, $fields, $rows);
    } else {
        $self->to_sql($table, $fields, $rows);
    }
}

sub to_sql {
    my ($self, $table, $fields, $rows) = @_;

    my $format;
    my $record_sep;
    if ($self->pretty) {
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
    my $columns = join ',', map { '`' . $_->name . '`' } @$fields;
    my $insert_stmt = sprintf $format, $table->name, $columns;

    my $sqls = '';
    my @values;
    my $sum_bytes = bytes::length($insert_stmt) + 1; # +1 is for trailing semicolon of sql
    my $record_sep_len = bytes::length($record_sep);
    my $bytes_per_sql = $self->bytes_per_sql;
    for my $row (@$rows) {
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
    return $sqls;
}

sub to_json {
    my ($self, $table, $fields, $rows) = @_;
    my $json = do {
        if ($self->pretty) {
            JSON->new->pretty;
        } else {
            JSON->new;
        }
    };

    use Data::Dumper;
    print Dumper $rows;
    return $json->encode({
        table => $table->name,
        fields => [ map { $_->name } @$fields ],
        values => $rows,
    });
}

1;
