package Data::FromDDL::RecordSet;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw(first);
use Class::Accessor::Lite (
    rw => [qw(table n cols)],
);
use JSON qw(encode_json);
use Data::FromDDL::Util qw(need_quote_data_type);

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
    push $self->{cols}, {
        field => $field,
        values => $values,
    };
}

sub get_values {
    my ($self, $field_name) = @_;
    my $col = first { $_->{field}->name eq $field_name } @{$self->cols};
    if ($col) {
        return wantarray ? @{$col->{values}} : $col->{values};
    } else {
        return undef;
    }
}

sub _construct_rows {
    my $self = shift;
    my $cols = $self->cols;
    my @rows;
    for my $i (0..($self->n)-1) {
        my $row = [map { 
            my $field = $_->{field};
            my $values = $_->{values};
            if (need_quote_data_type($field->data_type)) {
                "'" . $values->[$i] . "'";
            } else {
                $values->[$i];
            }
        } @$cols];
        push @rows, $row;
    }

    return @rows;
}

sub to_sql {
    my ($self, $pretty) = @_;
    my $cols = $self->cols;
    my @fields = map { $_->{field} } @$cols;
    my @rows = $self->_construct_rows;

    my $format;
    my $record_sep;
    if ($pretty) {
        $format = <<"EOL";
INSERT INTO
    `%s` (%s)
VALUES
    %s;
EOL
        $record_sep = ",\n    ";
    } else {
        $format = "INSERT INTO `%s` (%s) VALUES %s;";
        $record_sep = ',';
    }
    my $values = join $record_sep, map { "(" . join(',', @$_) . ")"; } @rows;
    my $columns = join ',', map { $_->name } @fields;
    return sprintf $format, $self->table->name, $columns, $values;
}

sub to_json {
    my ($self, $pretty) = @_;
    my $cols = $self->cols;
    my @fields = map { $_->{field} } @$cols;
    my @rows = $self->_construct_rows;
    # my $
}

sub to_yaml {
}

1;
