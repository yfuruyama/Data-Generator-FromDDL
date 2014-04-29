package Data::FromDDL::RecordSet;
use strict;
use warnings;
use Data::Dumper;

sub new {
    
}

sub to_sql {
    my $self = shift;
    # my $table = $self->table;
    # my $table_name = $table->name;
    # my @fields = $table->get_fields;
    # my $records = $self->records;
    # my @rows;
    # for my $i (0..($self->n)-1) {
        # my $row = join ',', map { 
            # if (_is_string_type($_->data_type)) {
                # "'" . $records->{$_->name}->[$i] . "'";
            # } else {
                # $records->{$_->name}->[$i];
            # }
        # } @fields;
        # push @rows, "($row)";
    # }
    # my $format = "-- $table_name\nINSERT INTO `%s` (%s) VALUES %s;\n\n";
    # my $columns = join ',', map { $_->name } @fields;
    # my $values = join ',', @rows;
    # return sprintf $format, $table_name, $columns, $values;
}

sub to_json {
}

sub to_yaml {
}

1;
