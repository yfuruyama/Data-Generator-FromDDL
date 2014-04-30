# NAME

DataGen::FromDDL - Dummy data generator from DDL statements

# SYNOPSIS

    use DataGen::FromDDL;

    my $generator = DataGen::FromDDL->new({
        ddl => 'CREATE TABLE users (....);',
        parser => 'mysql',
    });
    $generator->generate(100);

# DESCRIPTION

DataGen::FromDDL is dummy data generator intended to easily prepare dummy records for RDBMS.
This module takes care of some constraints specific to RDBMS and generates records in the right order.

Currently, composite (PRIMARY|UNIQUE|FOREIGN) KEY constraints are not supported.

# METHODS

- **new**

        DataGen::FromDDL->new(%options);

    Create a new instance.
    Possible options are:

    - ddl => $ddl

        Description of DDL. This option is required.

    - parser => $parser // 'MySQL'

        Parser for ddl. Choices are 'MySQL', 'SQLite', 'Oracle', or 'PostgreSQL'.

    - builder\_class => $builder\_class // 'DataGen::FromDDL::Builder::SerialOrder'

        Builder class.

    - include => \[@tables\] // \[\]

        Target tables.

    - exclude => \[@tables\] // \[\]

        Ignored tables.

- **generate**

        $generator->generate($num, $out_fh, $format, $pretty);

    Generate dummy data.

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
