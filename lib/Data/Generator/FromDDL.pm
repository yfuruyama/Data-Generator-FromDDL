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

our $VERSION = "0.02";

sub generate {
    my ($self, $num, $out_fh, $format, $pretty, $bytes_per_sql) = @_;

    # set default values if not specified
    my $builder_class = $self->builder_class
        || 'Data::Generator::FromDDL::Builder::SerialOrder';
    my $parser = $self->parser || 'mysql';
    my $include = $self->include || [];
    my $exclude = $self->exclude || [];
    my $ddl = $self->ddl || '';
    $out_fh ||= *STDOUT;
    $format ||= 'sql';
    $bytes_per_sql ||= 1024 * 1024; # 1MB;

    my $director = Data::Generator::FromDDL::Director->new({
        builder_class => $builder_class,
        parser => $parser,
        ddl => $ddl,
        include => $include,
        exclude => $exclude,
        out_fh => $out_fh,
    });

    my @recordsets = $director->generate($num);
    $director->flush(
        \@recordsets, $out_fh, $format, $pretty, $bytes_per_sql
    );
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
    $generator->generate(100); # Generated data are written to STDOUT.

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

    $generator->generate($num, $out_fh, $format, $pretty, $bytes_per_sql);

Arguments are:

=over 4

=item $num

Number of records generated.

=item $out_fh (default: *STDOUT)

File handle object to which records are dumped.

=item $format (default: 'sql')

Output format. Choices are B<'sql'> or B<'json'>.

=item $pretty (default: false)

Boolean value whether to print output prettily.

=item $bytes_per_sql (default: 1048576(1MB))

The maximum bytes of bulk insert statement.

This argument is releated to the MySQL's B<'max_allowed_packet'> variable which stands for the maximum size of string. It's recommended to suit this argument for your MySQL settings.

cf. https://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html#sysvar_max_allowed_packet

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

