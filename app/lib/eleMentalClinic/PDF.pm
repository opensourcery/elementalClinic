package eleMentalClinic::PDF;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::PDF

=head1 SYNOPSIS

Writes PDFs.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use PDF::Reuse;
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods { [ qw/ template_path filename /] }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 PSD::Reuse::errLog( $message )

Overrides existing method.  L<PDF::Reuse>, whatever its other stellar
qualities, has a hard-coded log file path.  It also has an incredibly intricate
error logging mechanism, which fails completely if it doesn't have write-access
to that path.  We get around this by overriding its error handler.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub PDF::Reuse::errLog {
    croak shift;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init( $args )

Object method. Sets up the path for where to look for PDF templates.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    $self->template_path( $self->config->template_path .'/pdf/' );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 start_pdf( $filename, $form )

Object method.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub start_pdf {
    my $self = shift;
    my( $filename, $form ) = @_; 
    return unless $filename;

    # file to generate
    prFile( $filename );

    # file to use as a template (move it over by the configurable amount)
    prForm({ 
        file => $self->template_path . $form . '.pdf', 
        x => $self->config->pdf_move_x,
        y => $self->config->pdf_move_y,
    }) if $form;
    
    $self->filename( $filename );
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 adjustmbox( $lowerLeftX, $lowerLeftY, $upperRightX, $upperRightY )

Object method. Wrapper for prMbox.
PDF::Reuse defaults to 0, 0, 595, 842 if this method is not called.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub adjustmbox {
    my $self = shift;
    my( $lowerLeftX, $lowerLeftY, $upperRightX, $upperRightY ) = @_;
    return unless $self->filename;

    PDF::Reuse::prMbox( $lowerLeftX, $lowerLeftY, $upperRightX, $upperRightY );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 write_pdf( $fields )

Object method. Must have called start_pdf already.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub write_pdf {
    my $self = shift;
    my( $fields ) = @_;
    return unless $fields;
   
    # must have called start_pdf first
    return unless $self->filename;

    for my $field ( @$fields ){
        
        # Move everything over by a configurable amount
        my $x = $field->{ x } + $self->config->pdf_move_x;
        my $y = $field->{ y } + $self->config->pdf_move_y;

        prText( $x, $y, $field->{ value }, $field->{ align } );
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 newpage

Object method. Must have called start_pdf already.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub newpage {
    my $self = shift;
   
    # must have called start_pdf first
    return unless $self->filename;

    prPage();
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 finish_pdf

Object method. Must have called start_pdf already.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub finish_pdf {
    my $self = shift;
   
    # must have called start_pdf first
    return unless $self->filename;

    prEnd();

    return $self->filename;
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Randall Hansen L<randall@opensourcery.com>

=item Kirsten Comandich L<kirsten@opensourcery.com>

=item Josh Heumann L<josh@joshheumann.com>

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
