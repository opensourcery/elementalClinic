package eleMentalClinic::Financial::WriteClaim;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Financial::WriteClaim

=head1 SYNOPSIS

Writes Insurance Claims, other classes can inherit from in order to write
specific formats, for example HCFA or 837.

=head1 DESCRIPTION

WriteClaim is a simple wrapper for controlling production of electronic
and paper insurance claim forms from eleMentalClinic::Financial::BillingFile objects.

New instances must be passed a valid BillingFile object or the constructor will die.

date_stamp and time_stamp properties will be automatically set when this object is
created, based on current date and time.  Alternatively, these may be overwritten
for testing purposes, either as arguments to the constructor, or by explicit property
calls:

    $write_claim->date_stamp = '20060629';
    $write_claim->time_stamp = '1604';

=head1 Usage

Use a class that overrides this one, such as Write837 or HCFA.

=head1 Properties

(Note: these properties can be set in the constructor, or reset after construction.)

=over 4

=item billing_file

Reference to an instantiated eleMentalclinic::Financial::BillingFile object our WriteClaim will be producing form data from.

=item date_stamp

Date stamp string that will be passed into the output.  Defaults to a 'yyyymmdd' string at date of construction.

=item time_stamp

Time stamp string that will be passed into the output.  Defaults to a 'hhmm' string at date of construction.

=back

(Note: these properties can only be reset after construction.)

=over 4

=item template

Template for processing.

=item output_root

Returns the path to the directory where outbound files should be written.

=item valid_lengths

A hash storing min and max lengths for fields. In this example:

{ control_number => '3, 5', }

the field 'control_number' must have a min of 3 characters, and a max of 5.

=back

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /;
use Data::Dumper;
use Date::Calc qw/ Today Now /;
use eleMentalClinic::ECS::Template;
use Data::Transformer;
use eleMentalClinic::Log;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{

    # XXX these aren't real fields in the database, but we use 'fields' to get 
    # them to be set in the constructor
    sub fields {
        [ qw/ billing_file date_stamp time_stamp / ]
    }

    sub fields_required {
        [ qw/ billing_file / ]
    }

    sub methods {
        [ qw/ template output_root valid_lengths / ]
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init( $args[, $options] )

Object method.

Initializes the object, sets properties based on passed parameters and sets
defaults for unset properties.

Billing_file must be a valid, instantiated eleMentalClinic::Financial::BillingFile object, or init() will die.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    my( $args, $options ) = @_;

    $self->SUPER::init( $args, $options );

    # this doesn't guard $self->billing_file(foo) ... may not be a fixable issue
    # ($self->billing_file might not exist if we've used $CLASS->empty)
    if( $self->billing_file ){
        $self->billing_file->isa("eleMentalClinic::Financial::BillingFile")
            or die 'billing_file parameter is not an eleMentalClinic::Financial::BillingFile.';
    }
    
    $self->defaults;

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 defaults

Sets core object properties, unless they have already been set.

 * date_stamp, time_stamp are set automatically unless passed in the 
constructor.

=cut

sub defaults {
    my $self = shift;
    
    $self->date_stamp( sprintf '%02d%02d%02d', Today )
        unless $self->date_stamp;
    $self->time_stamp( sprintf '%02d%02d', Now )
        unless $self->time_stamp;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 make_filename

Must be overridden in child class.

Returns a filename in the format specified by the type of file we will generate.

=cut

sub make_filename {
    my $self = shift;

    die 'You must override eleMentalClinic::Financial::WriteClaim::make_filename() with your own code.';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write()

Object method.

Generates the claim data and writes it to a file.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write {
    my $self = shift;

    die 'You must override eleMentalClinic::Financial::WriteClaim::make_filename() with your own code.';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_gender_f

Class method. Formatting for 837 ECS, also used in HCFAs

Takes a string that is either "Male" or "Female" and returns
'M' or 'F'. If neither Male nor Female, returns 'U'.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_gender_f {
    my $class = shift;
    my( $gender ) = @_;

    return unless $gender;

    return $gender eq 'Male'   ? 'M'
         : $gender eq 'Female' ? 'F'
         :                       'U';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_insurance_rank_f

Class method. Formatting for 837 ECS.  TODO move?

Takes a number that is either 1, 2 or other. Returns
'P' for 1, 'S' for 2, 'T' for any other number. Returns undef
for anything other than a single digit number.

P = primary (only one for OMAP), S = secondary, T = other

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_insurance_rank_f {
    my $class = shift;
    my( $rank ) = @_;

    return unless $rank and $rank =~ /^\d$/;

    return $rank == 1 ? 'P'
         : $rank == 2 ? 'S'
         :              'T';
}

=head2 split_charge_code

Class method. Formatting for 837 ECS and HCFAs.

Takes a valid_data_charge_code.name.
There may be two-digit modifiers appended to the end of the procedure code, 
which is always 5 characters. For example: 90801HK

Returns the code by itself, and an array of modifiers.

=cut

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub split_charge_code {
    my $class = shift;
    my( $code ) = @_;

    die 'code is required and must include at least 5 characters' unless $code and $code =~ /^\w{5}/;

    $code =~ s/^(\w{5})(.*)/$1/;
   
    my $modifiers;
    my $remaining = $2;

    # NOTE: Our clinic's real data includes a record with a space: "T1016 HN" - handle that too
    $remaining =~ s/^\s+//;

    while( $remaining ){
        # it seems weird to me to just bail with stuff possibly left in
        # $remaining, as will happen if there's an odd number of characters in
        # $remaining to begin with, but that's what the original code did, and
        # I guess it hasn't caused problems yet.  --hdp
        $remaining =~ s/^(\w{2})(.*)/$2/ or last;
        push @$modifiers => $1;
    }
   
    return( $code, $modifiers );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validate( $data )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validate {
    my $self = shift;
    my( $data ) = @_;

    return unless $data;
    
    my $methodref = sub { $self->validate_hash( @_ ) };
    my $transformer = Data::Transformer->new( hash => $methodref );
    $transformer->traverse( $data );
    
    return $data;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 validate_hash( $hashref )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub validate_hash {
    my $self = shift;
    my( $hashref ) = @_;

    return unless $hashref;
    return $hashref unless $self->valid_lengths;

    for my $key ( keys %$hashref ) {

        next unless defined $hashref->{ $key } and $hashref->{ $key } ne '';
        next unless $self->valid_lengths->{ $key };

        $self->valid_lengths->{ $key } =~ /(\d+), (\d+)/;
        my $min = $1; 
        my $max = $2; 
        next unless $min and $max;

       die "Length 'min' must be less than 'max.' (key $key, min $min, max $max)"
            if $min and defined $max and $min > $max;

        # catch the special case of the array, first
        if( ref $hashref->{ $key } eq "ARRAY" ){
            
            for my $value ( @{ $hashref->{ $key } } ){
                $value = $self->check_length( $key, $value, $min, $max ); 
            }
        }

        # skip if it's any other kind of reference
        next if ref $hashref->{ $key };

        $hashref->{ $key } = $self->check_length( $key, $hashref->{ $key }, $min, $max ); 
    }

    return $hashref;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 check_length( $key, $value, $min, $max )

Object method.

$min must be greater than zero, but it will only check the min. length
if $min is greater than one.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub check_length {
    my $self = shift;
    my( $key, $value, $min, $max ) = @_;

    return $value unless defined $value;
    return $value unless $key and $min and $max; 

    # check min
    if( $min > 1 ) {

        unless( $value =~ /^.{$min,}$/ ) {

            die "$key length must be at least $min characters long."
                unless $eleMentalClinic::Base::TESTMODE > 0;
            
            Log_defer( "Validate claim data: [$key] length must be at least $min characters long, current value is [$value]\n" );
        }
    }

    # check max
    return $value if $value =~ /^.{0,$max}$/;

    # we're over-max
    $value = substr( $value, 0, $max );

    Log_defer( "Validate claim data: [$key] length must be at most $max characters long, characters were truncated to [$value]\n" );

    return $value;
}

'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Partlow L<jpartlow@opensourcery.com>

=back

=head1 BUGS

We strive for perfection but are, in fact, mortal.  Please see L<https://prefect.opensourcery.com:444/projects/elementalclinic/report/1> for known bugs.

=head1 SEE ALSO

=over 4

=item Project web site at: L<http://elementalclinic.org>

=item Code management site at: L<https://prefect.opensourcery.com:444/projects/elementalclinic/>

=back

=head1 COPYRIGHT

Copyright (C) 2004-2007 OpenSourcery, LLC

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
