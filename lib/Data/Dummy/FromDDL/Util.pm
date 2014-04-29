package Data::Dummy::FromDDL::Util;
use 5.008005;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
    normalize_parser_str
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

1;
