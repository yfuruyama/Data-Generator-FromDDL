package Data::Generator::FromDDL::Director;
use strict;
use warnings;
use Carp qw(croak);
use List::MoreUtils qw(any);
use Class::Accessor::Lite (
    rw => [qw(builder_class parser ddl include exclude)],
);

use Data::Generator::FromDDL::Util qw(normalize_parser_str);
use Data::Generator::FromDDL::RecordSet;

sub new {
    my ($class, $args) = @_;

    my $builder_class = $args->{builder_class};
    my $builder_file = $builder_class;
    $builder_file =~ s!::!/!g;
    eval {
        require "$builder_file.pm";
    };
    if ($@) {
        croak("Can't require $builder_class");
    }

    return bless $args, $class;
}

sub generate {
    my ($self, $num) = @_;
    my @tables = $self->_get_right_order_tables;
    croak("No tables found: You might not specify all tables.")
        unless @tables;

    my @recordsets;
    for my $table (@tables) {
        my $builder = $self->builder_class->new({
            table => $table,
            recordsets => \@recordsets,
        });
        my $n = $self->_get_num_for_table($num, $table->name);
        if ($n) {
            push @recordsets, $builder->generate($n);
        }
    }
    return @recordsets;
}

sub _get_num_for_table {
    my ($self, $num, $table_name) = @_;
    if (ref $num eq 'HASH') {
        return exists $num->{tables}{$table_name} ? 
            $num->{tables}{$table_name} :
            $num->{all};
    } else {
        return $num;
    }
}

sub _get_right_order_tables {
    my $self = shift;
    my @tables = $self->_get_all_tables;
    my @filtered = $self->_filter_tables(\@tables);
    return $self->_resolve_data_generation_order(\@filtered);
}

sub _get_all_tables {
    my $self = shift;
    my $tr = SQL::Translator->new;
    $tr->parser(normalize_parser_str($self->parser))->($tr, $self->ddl);
    die "\nParsing DDL failed. Please check a DDL syntax.\n"
        unless $tr->schema->is_valid;
    return $tr->schema->get_tables;
}

sub _filter_tables {
    my ($self, $tables) = @_;
    my @include = @{$self->include};
    my @exclude = @{$self->exclude};

    my @filtered;
    if (scalar(@include)) {
        for my $t (@$tables) {
            push @filtered, $t if any { $t->name eq $_ } @include;
        }
    } elsif (scalar(@exclude)) {
        for my $t (@$tables) {
            push @filtered, $t unless any { $t->name eq $_ } @exclude;
        }
    } else {
        @filtered = @$tables;
    }

    return @filtered;
}

sub _resolve_data_generation_order {
    my ($self, $tables) = @_;
    my @unresolved = @$tables;
    my @resolved;
    while (@unresolved) {
        $self->_resolve_inter_table_reference(\@unresolved, \@resolved);
    }
    return @resolved;
}

sub _resolve_inter_table_reference {
    my ($self, $unresolved, $resolved) = @_;
    my @old_unresolved = @$unresolved;
    splice @$unresolved, 0;

    for my $ur (@old_unresolved) {
        if ($self->_exist_all_foreign_key_reference($ur, $resolved)) {
            push @$resolved, $ur;
        } else {
            push @$unresolved, $ur;
        }
    }
}

sub _exist_all_foreign_key_reference {
    my ($self, $table, $others) = @_;
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
