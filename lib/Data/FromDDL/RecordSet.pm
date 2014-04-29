package Data::FromDDL::RecordSet;
use strict;
use warnings;
use Data::Dumper;
use Data::FromDDL::Util qw(is_string_data_type);

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

sub to_sql {
    my $self = shift;
    my $cols = $self->{cols};
    my @fields = map { $_->{field} } @$cols;
    my @rows;
    for my $i (0..($self->{n})-1) {
        my $row = join ',', map { 
            my $field = $_->{field};
            my $values = $_->{values};
            if (is_string_data_type($field->data_type)) {
                "'" . $values->[$i] . "'";
            } else {
                $values->[$i];
            }
        } @$cols;
        push @rows, "($row)";
    }

    my $format = "INSERT INTO `%s` (%s) VALUES %s;";
    my $columns = join ',', map { $_->name } @fields;
    my $values = join ',', @rows;
    return sprintf $format, $self->{table}->name, $columns, $values;
}

sub to_json {
}

sub to_yaml {
}

1;
