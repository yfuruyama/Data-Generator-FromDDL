package Data::FromDDL::Util;
use 5.008005;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
    normalize_parser_str
    is_string_data_type
);

sub normalize_parser_str {
    my $parser = shift;
    if ($parser =~ /mysql/i) {
        return 'MySQL';
    } elsif ($parser =~ /sqlite/i) {
        return 'SQLite';
    } elsif ($parser =~ /oracle/i) {
        return 'Oracle';
    } elsif ($parser =~ /postgresql/i) {
        return 'PostgreSQL';
    }

    return $parser;
}

sub is_string_data_type {
    my $data_type = lc(shift);
    if ($data_type eq 'char' or 
        $data_type eq 'varchar' or
        $data_type eq 'tinytext' or
        $data_type eq 'text' or
        $data_type eq 'mediumtext') {
        return 1;
    } else {
        return undef;
    }
}


1;
