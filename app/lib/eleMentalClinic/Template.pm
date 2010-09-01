# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Template;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Template

=head1 SYNOPSIS

Parent template object.  Abstracts Template::Toolkit with site-specific features.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::Base /;
use eleMentalClinic::Util;
use Template 1.10;
use Data::Dumper;
use Date::Calc qw/ Month_to_Text /;
use List::MoreUtils ();
use Scalar::Util ();
use JSON ();
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods { [ qw/
        template template_markers controller
    /] }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub defaults {
    {
        template_markers    => 1,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    my %defaults = %{ &defaults };
    while( my( $key, $value ) = each %defaults ) {
        defined $args->{ $key }
            ? $self->$key( $args->{ $key })
            : $self->$key( $value );
    }

    # this reference would be circular otherwise
    $self->controller( $args->{controller} );
    Scalar::Util::weaken( $self->{controller} );

    $self->vars( $args->{ vars });
    $self->init_custom_methods;
    $self->init_template;
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init_custom_methods {
    my $self = shift;

    $Template::Stash::LIST_OPS->{ sort_roles_by_homepage } = sub {
        my $list = shift;
        return [ sort { $a->has_homepage <=> $b->has_homepage } sort { $a->name cmp $b->name } @$list ];
    };

    $Template::Stash::SCALAR_OPS->{ format_date_long } = sub {
        my $date = shift;
        return unless $date;
        my( $year, $month, $day ) = split /-/ => ( split / / => $date )[ 0 ];
        return sprintf( "%s %s, %d",
            Month_to_Text( $month ),
            $day * 1,
            $year
        );
    };

    $Template::Stash::SCALAR_OPS->{ format_date_medium } = sub {
        my $date = shift;
        return unless $date;
        my( $year, $month, $day ) = split /-/ => ( split / / => $date )[ 0 ];
        return sprintf( "%.3s %s, %d",
            Month_to_Text( $month ),
            $day * 1,
            $year
        );
    };

    $Template::Stash::SCALAR_OPS->{ format_date } = sub {
        return format_date( @_ );
    };

    $Template::Stash::SCALAR_OPS->{ format_date_time } = sub {
        return format_date_time( @_ );
    };

    $Template::Stash::SCALAR_OPS->{ format_date_remove_time } = sub {
        return format_date_remove_time( @_ );
    };

    $Template::Stash::SCALAR_OPS->{ format_date_month_name } = sub {
        my $date = shift;
        return unless $date;
        my( $year, $month, $day ) = split /-/ => ( split / / => $date )[ 0 ];
        return Month_to_Text( $month );
    };

    $Template::Stash::SCALAR_OPS->{ date_calc } = sub {
        my( $date, $delta ) = @_;
        return date_calc( $date, $delta );
    };

    $Template::Stash::SCALAR_OPS->{ date_month_name } = sub {
        my( $date ) = @_;
        return date_month_name( $date );
    };

    $Template::Stash::SCALAR_OPS->{ date_year } = sub {
        my( $date ) = @_;
        return date_year( $date );
    };

    $Template::Stash::SCALAR_OPS->{ format_ssn } = sub {
        my( $ssn ) = @_;
        return $ssn unless
            $ssn =~ /^\d{9}$/;
        $ssn =~ s/(\d{3})(\d{2})(\d{4})/$1-$2-$3/;
        return $ssn;
    };

    $Template::Stash::SCALAR_OPS->{ time_format } = sub {
        my ( $time, $format ) = @_;
        return dynamic_time_format_factory(undef, $format)->($time);
    };

    $Template::Stash::SCALAR_OPS->{ pad_right } = sub {
        my( $string, $padding, $length ) = @_;

        my $num_padding = ($length - length $string) / length $padding;
        return $string . $padding x $num_padding;
    };
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init_template {
    my $self = shift;

    my $config = {
        INCLUDE_PATH => [
            List::MoreUtils::uniq(
                $self->config->template_path,
                $self->config->default_template_path,
            )
        ],
        POST_CHOMP  => 0,
        EVAL_PERL   => 1,
        FILTERS => {
            date_format => [ \&dynamic_date_format_factory, 1 ],
            time_format => [ \&dynamic_time_format_factory, 1 ],
        }
    };

    my %map = (
        Base => Template::Provider->new({
            %$config,
            INCLUDE_PATH => [ $self->config->default_template_path ],
        }),
    );
    $map{Default} = $map{Base};

    $self->template( Template->new({
        %$config,
        PREFIX_MAP => \%map,
    }) );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 dynamic_time_format_factory()

For outputing times in different formats inside template toolkit
using FILTER time_format('format').  Where <format> may be:

iso : hh:mm:ss
24  : [h]h:mm - no leading zero
12  : [h]h:mm a/p

See Template Toolkit FILTER extension docs for details.

=cut

sub dynamic_time_format_factory {
    my ($context, $time_format) = @_;
    $time_format ||= 'iso';

    return sub {
        my $text = shift;
       
        return unless $text;
 
        my( $h, $m, $s, $ampm ) = $text =~ qr/^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(a|am|p|pm)?\s*$/;
        $s ||= 0;
        $ampm ||= '';
#        print Dumper [$h, $m, $s, $ampm];
        return $text unless defined $h;

        if ($time_format eq '24' ) {
            return sprintf('%d:%02d', to_24($h, $ampm), $m);
        }
        elsif ($time_format eq '12' ) {
            my ($h_converted, $ampm_converted) = ($h, $ampm);
            unless ($ampm) {
                ($h_converted, $ampm_converted ) = to_12($h);
            }
            return sprintf('%d:%02d %s', $h_converted, $m, $ampm_converted);
        }
        # default to iso
        return sprintf('%02d:%02d:%02d', to_24($h, $ampm), $m, $s);
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 to_24()

Switches a 12 hour hour and $ampm designation to a 24 hour hour.

=cut

sub to_24 {
    my( $hour, $ampm ) = @_;

    return unless $hour;

    my $h = $hour;
    if ($ampm && $ampm =~ qr/^am?$/) {
        $h = 0 if $hour == 12;
    } elsif ($ampm && $ampm =~ qr/^pm?$/) {
        $h += 12 if $hour != 12;
    }
    return $h;

}

=head1 to_12() 

Switches a 24hr hour to a 12 hour hour and ampm designation.

=cut

sub to_12 {
    my( $hour ) = @_;

    return unless defined $hour;

    my $h = $hour;
    my $ampm = $hour >= 12 ? 'p' : 'a';

    $h -= 12 if $hour > 12;
    $h = 12 if $hour == 0;

    return ($h, $ampm); 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 dynamic_date_format_factory()

For outputing dates in different formats inside template toolkit
using FILTER date_format('format').  Where <format> may be one
of the formats listed in eleMentalClinic::Personnel::Prefs.'

See Template Toolkit FILTER extension docs for details.

=cut

sub dynamic_date_format_factory {
    my ($context, $date_format) = @_;
    $date_format ||= 'sql';

    return sub {
        my $text = shift;
        
        # assume $text is iso date
        my( $y, $m, $d ) = $text =~ /^(\d{4})-(\d{1,2})-(\d{1,2})$/;
        return $text unless defined $y;

        if ($date_format eq 'mdy') {
            return sprintf( '%02d/%02d/%d', $m, $d, $y );
        }
        # default sql
        return sprintf( '%d-%02d-%02d', $y, $m, $d );           
    } 
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_block {
    my $self = shift;
    my( $block_name, $params ) = @_;
    return unless $params;

    my $html;
    my $ret = eval { $self->template->process( "$block_name.html", $params, \$html ) };
    croak( $@ ) if $@;
    if ( $ret )
    {
        my ( $begin_comment, $end_comment ) = ( '', '' );
        if ( $self->template_markers ) {
            $begin_comment = "<!-- $block_name BEGIN -->";
            $end_comment   = "<!-- $block_name END -->";
        }

        return "$begin_comment\n$html $end_comment\n";
    }
    elsif ( $self->template->error ) {
        # XXX these paths won't work for templates that have fallen back
        # we should be able to get this information right out of Template Toolkit
        my $msg = $self->template->error . ' [template path:' . $self->config->template_path . ']';
        $self->exception( $msg, $block_name, $params )->throw;
    }
    elsif ( -f join("/", $self->config->template_path, "$block_name.html") ) {
        my $msg = "Template file not found: ".join("/", $self->config->template_path, "$block_name.html");
        $self->exception( $msg, $block_name, $params )->throw;
    }

    return "<!-- $block_name FAILED -->";
}

sub exception {
    my $self = shift;
    my ( $error, $block_name, $params ) = @_;
    my $report = eleMentalClinic::Log::ExceptionReport->new({
        name => 'Template Error',
        message => $error,
        params => {
            'caller' => [ caller( 2 ) ],
            template_path => $self->config->template_path,
            block_name => $block_name,
            params => $params,
        }
    });
    return $report;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_page {
    my $self = shift;
    my( $page, $params ) = @_;

    my %template_params = %{ $self->vars }
        if $self->vars;
    %template_params = ( %template_params, %{ $params })
        if $params;
    $template_params{Controller} = $self->controller;
    $template_params{to_json} = sub { JSON::to_json($_[0]) };

    $self->process_block( $page, \%template_params );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub print_page {
    my $self = shift;
    my( $page, $params ) = @_;

    print $self->process_page( $page, $params );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if incoming hashref, adds key/values to current vars
# if incoming scalar, returns its value or undef
# if no params, returns all as harhref
sub vars {
    my $self = shift;
    my( $vars ) = @_;

    if( $vars and ref $vars eq 'HASH' ) {
        while( my( $key, $val ) = each %$vars ) {
            $self->{ vars }{ $key } = $val;
        }
        return;
    }
    elsif( $vars ) {
        return $self->{ vars }{ $vars }
            ? $self->{ vars }{ $vars }
            : undef;
    }

    return $self->{ vars }
        ? $self->{ vars }
        : undef;
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
