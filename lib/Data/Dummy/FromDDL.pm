package Data::Dummy::FromDDL;
use 5.008005;
use strict;
use warnings;
use SQL::Translator;
use Data::Dumper;
use Data::Dummy::FromDDL::Generator;
use List::MoreUtils qw(any);

our $VERSION = "0.01";

sub new {
    my ($class, @args) = @_;
    return bless {
        @args
    }, $class;
}

# 複合PRIMARY KEYは厳しいかも
sub generate {
    my ($self, $n) = @_;
    my $tr = SQL::Translator->new;
    $tr->parser($self->{parser})->($tr, $self->{ddl});

    my @tables = $tr->schema->get_tables;
    my @filtered_tables = filter_tables(\@tables, $self->{include}, $self->{exclude});

    my $resolved = resolve_data_generation_order(\@filtered_tables);
    # print $_->name . "\n" for @$resolved;

    my @generators;
    my $out_fh = $self->{out_fh};
    for (@$resolved) {
        my $generator = Data::Dummy::FromDDL::Generator->new($_);
        $generator->generate($n, \@generators);
        push @generators, $generator;
        print $out_fh $generator->to_sql_insert_clause;
    }
}

sub filter_tables {
    my ($tables, $include, $exclude) = @_;

    my @filtered;
    if (scalar(@$include)) {
        for my $t (@$tables) {
            push @filtered, $t if any { $t->name eq $_ } @$include;
        }
    } elsif (scalar(@$exclude)) {
        for my $t (@$tables) {
            push @filtered, $t unless any { $t->name eq $_ } @$exclude;
        }
    } else {
        @filtered = @$tables;
    }

    return @filtered;
}

sub resolve_data_generation_order {
    my $tables = shift;
    my @unresolved = @$tables;
    my @resolved;
    while (@unresolved) {
        _resolve_inter_table_reference(\@unresolved, \@resolved);
    }
    return \@resolved;
}

sub _resolve_inter_table_reference {
    my ($unresolved, $resolved) = @_;
    my @old_unresolved = @$unresolved;
    splice @$unresolved, 0;

    for my $ur (@old_unresolved) {
        if (_exist_all_foreign_key_reference($ur, $resolved)) {
            push @$resolved, $ur;
        } else {
            push @$unresolved, $ur;
        }
    }
}

sub _exist_all_foreign_key_reference {
    my ($table, $others) = @_;
    my @fk_constraints = grep { uc($_->type) eq 'FOREIGN KEY' }
        $table->get_constraints;
    for my $constraint (@fk_constraints) {
        my $ref_table = $constraint->reference_table;
        unless (grep { $ref_table eq $_->name } @$others) {
            return undef;
        }
    }
    return 1;
}


1;
__END__

=encoding utf-8

=head1 NAME

Data::Dummy::FromDDL - It's new $module

=head1 SYNOPSIS

    use Data::Dummy::FromDDL;

=head1 DESCRIPTION

Data::Dummy::FromDDL is ...

How this module satisfies some database constraints.

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

