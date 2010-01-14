package eleMentalClinic::Util;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Util

=head1 SYNOPSIS

Exports utility functions.  Very early; some of C<eleMentalClinic::Base>'s
functions should come from here, instead.

=head1 FUNCTIONS

=cut

use base qw/ Exporter /;
use eleMentalClinic::DB;
use Date::Calc qw/ check_date Add_Delta_YMD Add_Delta_YM Month_to_Text /;
use Carp;
use Data::Dumper;

our @EXPORT = qw/
    dbquote
    dbquoteme
    date_calc
    format_date
    format_date_time
    format_date_remove_time
    _check_date
    date_month_name
    date_year
/;
our @EXPORT_OK = qw/
    _quote
/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 _quote( $value ![, $data_type ] )

Function; internal use only.

Behaves identically to C<DBI>'s C<quote()> method except that an undef
C<$value> will return C<undef> instead of "NULL".  C<$value> must be a scalar.
C<$data_type> is not yet supported.

C<eleMentalClinic::DB> must be initialized before this function can be used.
This is because different database drivers can use different C<quote()>
methods, and we want to be sure we use the right one.  In practice, this
matters only for testing.

For security purposes, C<_quote()> dies a grisly death if (a) you don't check
its return value, or (b) you pass it a reference.  That is to prevent
accidental use of C<_quote()> when you mean C<dbquoteme()>:

    $var = "1; DROP DATABASE";
    _quote( \$var );
    # run query using $var, hate life

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub _quote {
    my( $value, $data_type ) = @_;

    die 'eleMentalClinic::DB must be initialized.'
        unless $eleMentalClinic::DB::one_true_DBH;
    die q/It is an error to use _quote() without checking its return value.  See the POD./
        unless defined wantarray;
    die '$data_type as a second parameter is not yet supported'
        if defined $data_type;
    die q/The value passed to _quote() must a scalar.  See the POD./
        if ref $value;

    return unless defined $value;
    return $eleMentalClinic::DB::one_true_DBH->quote( $value );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 dbquote( @values )

Function; exported by default.

Each argument must be a scalar.  Executes C<_quote()> for each argument, then
returns them.  In list context returns an array; in scalar context returns
B<the first element>.

C<eleMentalClinic::DB> must be initialized before this function can be used.
This is because different database drivers can use different C<quote()>
methods, and we want to be sure we use the right one.  In practice, this
matters only for testing.

For security purposes, C<dbquote()> dies a grisly death if you (a) don't check
its return values, or (b) you pass it a reference.  This is to prevent
accidental use of C<dbquote()> when you mean C<dbquoteme()>:

    $var = "1; DROP DATABASE";
    dbquote( \$var );
    # run query using $var, hate life

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub dbquote {
    my( @values ) = @_;

    die 'eleMentalClinic::DB must be initialized.'
        unless $eleMentalClinic::DB::one_true_DBH;
    return unless @values;
    die q/It is an error to use dbquote() without checking its return value.  See the POD./
        unless defined wantarray;
    map{ ref $_ and die q/Values passed to dbquote() must be scalars.  See the POD./} @values;
    for( @values ) {
        die q/Values passed to dbquote() must be scalars.  See the POD./
            if ref $_;
    }

    # cannot use map here because it ignores 'undef'
    my @quoted;
    for( @values ) {
        push @quoted => ( defined _quote $_ )
            ? _quote $_
            : undef;
    }
    return wantarray
        ? @quoted
        : $quoted[ 0 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 dbquoteme( @values )

Function; exported by default.

Each argument must be a reference to a scalar variable.  Executes C<_quote()>
on each argument's referrant.  This makes it easy to change a value in-place.
E.g.:

    dbquoteme( \$value );

C<eleMentalClinic::DB> must be initialized before this function can be used.
This is because different database drivers can use different C<quote()>
methods, and we want to be sure we use the right one.  In practice, this
matters only for testing.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub dbquoteme {
    my( @values ) = @_;

    die 'eleMentalClinic::DB must be initialized.'
        unless $eleMentalClinic::DB::one_true_DBH;
    return unless @values;

    for my $val( @values ) {
        next unless defined $val;
        croak "Each value passed to dbquoteme() must be a REFERENCE to a scalar ( $val )"
            unless ref $val and ref $val eq 'SCALAR';
        $$val = _quote $$val;
    }
    return "0E0"; # true but useless, standard for DBI module
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 _check_date( $date, $required )

Function.

Checks that C<$date> is in ISO format (i.e. YYYY-MM-DD).  Dies if not.  Also
dies if C<$required> is true and C<$date> is not present.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub _check_date {
    my( $date, $required ) = @_;

    die 'Date is required.'
        if $required and not $date;
    return
        unless $date;

    # Date::Calc dies with bad input, but we want a better error message
    my $ok;
    eval{ $ok = check_date( split /-/ => $date )}
        unless $date =~ /[^\d\-]/;
    croak 'Date must be in ISO format.'
        if $@ or not $ok;
    return $date;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 date_calc( $date[, $delta ])

Function; exported by default.

Does math on C<$date> to change it by C<$delta>.  If C<$delta> evaluates as
false, returns C<$date> unchanged.

Example C<$delta> values are: C<1m>, C<-2y>, C<+30d>.  C<$delta> consists of
three parts:  a sign, an increment, and a unit.

=over 4

=item sign

Optional.  If present, must be '-' or '+'.

=item increment

Required.  Must be integer.

=item unit

Required.  Must be 'y', 'm', or 'd'.

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub date_calc {
    my( $date, $delta ) = @_;

    _check_date( $date, 'required' );
    return $date
        unless defined $delta;

    $delta =~ /^(\D)?(\d+)([ymd])$/;
    my( $sign, $amount, $unit ) = ( $1, $2, $3 );

    die "Invalid sign: $sign.  See POD"
        if $sign and not ( $sign eq '+' or $sign eq '-' );
    die 'Missing or invalid unit:'. ( $unit || '' ) .'.  See POD'
        unless $unit;

    return $date
        if defined $amount and $amount == 0;
    die 'Missing or invalid amount'
        unless $amount;

    $amount = $amount * -1
        if $sign and $sign eq '-';

    my $format = "%4d-%02d-%02d";
    $unit eq 'y' and return sprintf $format => Add_Delta_YM(( split /-/ => $date ), $amount, 0 );
    $unit eq 'm' and return sprintf $format => Add_Delta_YM(( split /-/ => $date ), 0, $amount );
    $unit eq 'd' and return sprintf $format => Add_Delta_YMD(( split /-/ => $date ), 0, 0, $amount );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 format_date()

Function

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub format_date {
    my( $date ) = @_;

    return unless
        _check_date( $date, 'required' );
    my( $year, $month, $day ) = split /-/ => $date;
    return sprintf( "%s/%s/%d",
        $month * 1,
        $day * 1,
        $year
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 format_date_time( $timestamp )

Function.

Returns a formatted timestamp as "M/D/YYYY @ hh:mm".

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub format_date_time {
    my( $timestamp ) = @_;

    die 'Timestamp is required'
        unless $timestamp;

    my( $date, $time ) = split / / => $timestamp;
    _check_date( $date );
    die 'Timestamp must be in YYYY-MM-DD hh:mm:ss format.'
        unless $time and my( $hour, $minutes, $seconds ) = split /:/ => $time;
    return format_date( $date ) ." @ $hour:$minutes";
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 format_date_remove_time( $timestamp )

Function.

Returns a formatted timestamp as "M/D/YYYY".

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub format_date_remove_time {
    my( $timestamp ) = @_;

    return ( split / / => format_date_time( $timestamp ) )[0];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 date_month_name( $date )

Function.  Exported by default.

Returns the name of the month specified by C<$date>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub date_month_name {
    my( $date ) = @_;

    _check_date( $date );
    return unless $date;
    $date =~ /^\d+-(\d+)-\d+$/;
    return Month_to_Text( $1 );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 date_year( $date )

Function.  Exported by default.

Returns the year of C<$date>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub date_year {
    my( $date ) = @_;

    _check_date( $date );
    return unless $date;
    $date =~ /(\d+)-\d+-\d+/;
    return $1;
}


# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub filter_contact_primary {
    my $self = shift;
    my $array = shift;

    return (grep $_->primary_entry, @$array)[0];
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub filter_contact_active {
    my $self = shift;
    my $array = shift;

    return [grep $_->active, @$array];
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2006-2007 OpenSourcery, LLC

This file is part of eleMental Clinic.

eleMental Clinic is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option) any
later version.

eleMental Clinic is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

eleMental Clinic is packaged with a copy of the GNU General Public License.
Please see docs/COPYING in this distribution.
