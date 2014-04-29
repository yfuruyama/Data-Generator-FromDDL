package Data::FromDDL;
use 5.008005;
use strict;
use warnings;
use SQL::Translator;
use Data::Dumper;
use Data::FromDDL::Director;

our $VERSION = "0.01";

sub new {
    my ($class, @args) = @_;
    return bless {
        @args
    }, $class;
}

# 複合PRIMARY KEYは厳しいかも
sub generate {
    my ($self, $n, $out_fh, $pretty) = @_;
    my $builder_class = $self->{builder_class}
        || 'Data::FromDDL::Builder::SerialOrder';
    my $director = Data::FromDDL::Director->new({
        builder_class => $builder_class,
        parser => $self->{parser},
        ddl => $self->{ddl},
        include => $self->{include},
        exclude => $self->{exclude},
    });
    my @recordsets = $director->generate($n);
    my $format = lc($self->{format}) || 'sql';

    my $output = do {
        if ($format eq 'sql') {
            join "\n\n", map { $_->to_sql($pretty) } @recordsets;
        } elsif ($format eq 'json') {
            # join "\n\n", map { $_->to_sql } @recordsets;
        }
    };
    print $out_fh $output . "\n";
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::FromDDL - It's new $module

=head1 SYNOPSIS

    use Data::FromDDL;

=head1 DESCRIPTION

Data::FromDDL is ...

How this module satisfies some database constraints.

Composite PRIMARY KEY and composite UNIQUE KEY is not currently supported.

=item PRIMARY KEY constraint

To be written...

=item UNIQUE KEY constraint

This module genereates records as uniquely as possible.

=item FOREIGN KEY constraint

To be written...

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

