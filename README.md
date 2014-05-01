# NAME

Data::Generator::FromDDL - Dummy data generator from DDL statements

# SYNOPSIS

    use Data::Generator::FromDDL;

    my $generator = Data::Generator::FromDDL->new({
        ddl => 'CREATE TABLE users (....);',
        parser => 'mysql',
    });
    $generator->generate(100);

# DESCRIPTION

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

# METHODS

- **new** - Create a new instance.

        Data::Generator::FromDDL->new(%options);

    Possible options are:

    - ddl => $ddl

        Description of DDL. This option is required.

    - parser => $parser // 'MySQL'

        Parser for ddl. Choices are 'MySQL', 'SQLite', 'Oracle', or 'PostgreSQL'.

    - builder\_class => $builder\_class // 'Data::Generator::FromDDL::Builder::SerialOrder'

        Builder class.

    - include => \[@tables\] // \[\]

        Target tables.

    - exclude => \[@tables\] // \[\]

        Ignored tables.

- **generate** - Generate dummy records.

        $generator->generate($num, $out_fh, $format, $pretty);

    Arguments are:

    - $num

        Number of records generated.

    - $out\_fh

        File handle object to which records are dumped.

    - $format

        Output format. Choices are **'sql'**, **'json'**, **'yaml'**.

    - $pretty

        Boolean value whether to print output prettily.

# COMMAND LINE INTERFACE

The `datagen_from_ddl(1)` command is provided as an interface to this module.

    $ datagen_from_ddl --num=100 --parser=mysql --pretty your_ddl.sql

For more details, please see [datagen\_from\_ddl](https://metacpan.org/pod/datagen_from_ddl)(1).

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
