package Data::FromDDL::Util;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(
    normalize_parser_str
    need_quote_data_type
    get_numeric_type_byte
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

sub need_quote_data_type {
    my $type = lc(shift);
    if ($type eq 'char' or 
        $type eq 'varchar' or
        $type eq 'tinytext' or
        $type eq 'text' or
        $type eq 'mediumtext' or
        $type eq 'timestamp') {
        return 1;
    } else {
        return undef;
    }
}

sub get_numeric_type_byte {
    my $type = lc(shift);
    if ($type eq 'bigint') {
        return 8;
    } elsif ($type eq 'int' or $type eq 'integer') {
        return 4;
    } elsif ($type eq 'mediumint') {
        return 3;
    } elsif ($type eq 'smallint') {
        return 2;
    } elsif ($type eq 'tinyint') {
        return 1;
    } elsif ($type eq 'timestamp') {
        # UNIX timestamps are signed integer
        return 4;
    }
}


1;
