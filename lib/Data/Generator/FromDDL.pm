package Data::Generator::FromDDL;
use 5.008005;
use strict;
use warnings;
use SQL::Translator;
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(builder_class parser ddl include exclude)],
);

use Data::Generator::FromDDL::Director;

our $VERSION = "0.01";

sub generate {
    my ($self, $num, $out_fh, $format, $pretty) = @_;
    my $builder_class = $self->builder_class
        || 'Data::Generator::FromDDL::Builder::SerialOrder';
    my $director = Data::Generator::FromDDL::Director->new({
        builder_class => $builder_class,
        parser => $self->parser || 'mysql',
        ddl => $self->ddl,
        include => $self->include || [],
        exclude => $self->exclude || [],
    });
    my @recordsets = $director->generate($num);

    my $output = do {
        my $formatter;
        if (defined($format) && lc($format) eq 'json') {
            $formatter = 'to_json';
        } elsif (defined($format) && lc($format) eq 'yaml') {
            $formatter = 'to_yaml';
        } else {
            $formatter = 'to_sql';
        }
        join "\n", map { $_->$formatter($pretty) } @recordsets;
    };

    $out_fh ||= *STDOUT;
    print $out_fh $output . "\n";
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Generator::FromDDL - Dummy data generator from DDL statements

=head1 SYNOPSIS

    use Data::Generator::FromDDL;

    my $generator = Data::Generator::FromDDL->new({
        ddl => 'CREATE TABLE users (....);',
        parser => 'mysql',
    });
    $generator->generate(100);

=head1 DESCRIPTION

Data::Generator::FromDDL is dummy data generator intended to easily prepare dummy records for RDBMS.
This module takes care of some constraints specific to RDBMS and generates records in the right order.

Supported constraints are

    - PRIMARY KEY
    - UNIQUE KEY
    - FOREIGN KEY

Supported data types are

    - BIGINT
    - INT (INTEGER)
    - MEDIUMINT
    - SMALLINT
    - TINYINT
    - TIMESTAMP
    - CHAR
    - VARCHAR
    - TINYTEXT
    - TEXT
    - MEDIUMTEXT
    - ENUM

Currently, composite (PRIMARY|UNIQUE|FOREIGN) KEY constraints are not supported.

=head1 METHODS

=over 4

=item B<new> - Create a new instance.

    Data::Generator::FromDDL->new(%options);

Possible options are:

=over 4

=item ddl => $ddl

Description of DDL. This option is required.

=item parser => $parser // 'MySQL'

Parser for ddl. Choices are 'MySQL', 'SQLite', 'Oracle', or 'PostgreSQL'.

=item builder_class => $builder_class // 'Data::Generator::FromDDL::Builder::SerialOrder'

Builder class.

=item include => [@tables] // []

Target tables.

=item exclude => [@tables] // []

Ignored tables.

=back

=item B<generate> - Generate dummy records.

    $generator->generate($num, $out_fh, $format, $pretty);

Arguments are:

=over 4

=item $num

Number of records generated.

=item $out_fh

File handle object to which records are dumped.

=item $format

Output format. Choices are B<'sql'>, B<'json'>, B<'yaml'>.

=item $pretty

Boolean value whether to print output prettily.

=back

=back

=head1 COMMAND LINE INTERFACE

The C<datagen_from_ddl(1)> command is provided as an interface to this module.

    $ datagen_from_ddl --num=100 --parser=mysql --pretty your_ddl.sql

For more details, please see L<datagen_from_ddl>(1).

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

