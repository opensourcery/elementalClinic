# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package eleMentalClinic::Base::Util;

use Sub::Exporter -setup => {
    exports => [qw(
        date_range_sql
        eman
        make_lookup_hash
        unique
    )],
};


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO this is horrible, but it works and is tested.
# replace it soon.
sub date_range_sql {
    my $self = shift;
    my ( $from_field, $to_field, $from, $to ) = @_;
    return unless $from_field and $to_field;
    my $where = "";

    $where .= " CAST ($from_field AS date) = CAST ('$from' AS date)"
        if defined $from and not defined $to;
    $where .= " CAST ($to_field AS date) = CAST ('$to' AS date)"
        if defined $to and not defined $from;

    if( defined $to and defined $from ){
        if( $to eq $from ){
            $where .= " ( CAST ($from_field AS date) = CAST ('$from' AS date)";
            $where .= " OR CAST ($to_field AS date) = CAST ('$to' AS date) )";
        }
        else {
            $where .= " ( CAST ($from_field AS date) >= CAST ('$from' AS date) )";
            $where .= " AND ( CAST ($to_field AS date) <= CAST ('$to' AS date) )";
        }
    }

    return $where;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns "$last $suffix, $first $trailing"
# $trailing is usually middle initial or credentials
sub eman {
    my $self = shift;
    my( $first, $last, $trailing, $suffix ) = @_;

    return unless $first or $last;

    my $eman;
    $eman = "$last $suffix, " if $last and $suffix;
    $eman = "$last, " if $last and not $suffix;

    $eman .= "$first " if $first;
    $eman .= "$trailing " if $trailing;

    $eman .= " $suffix " if $suffix and not $last;

    $eman =~ s/[, ]+$//; # nuke trailing commas
    $eman =~ s/  / /;    # nuke double spaces
    $eman;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub make_lookup_hash {
    my $self = shift;
    my( $arrayref ) = @_;

    return unless $arrayref;
    die 'Arrayref is required by Base::make_lookup_hash.'
        unless ref $arrayref eq 'ARRAY';

    my %hash = ();
    $hash{ $_ } = 1 for @$arrayref;
    \%hash;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# takes incoming values and returns unique ones, unsorted
# accepts arrays or arrayrefs, in any combination
# does NOT accept nested arrayrefs
# returns array
sub unique {
    my $self = shift;
    my @incoming = @_;

    return unless @incoming;
    my @elements = ();
    for( @incoming ) {
        next unless defined $_;
        push @elements => ( ref $_ and ref $_ eq 'ARRAY' )
            ? @$_
            : $_;
    }
    return unless @elements;
    my %seen = ();
    grep{ ! $seen{ $_ }++ } ( @elements );
}

1;
