package HTML::Calendar::Template;
use warnings;
use strict;

our $VERSION = '0.16';

use Oompa;
use base qw/ Oompa /;
use Carp;
use Template;
use Data::Dumper;
use Date::Calc qw/ Today check_date Month_to_Text Calendar Days_in_Month Add_Delta_YM /;
use File::Spec;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub fields {
    return qw/
        date month year
        _template template_path template_extension
        links classes
        orthodox
        vars
    /;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;

    my( $year, $month, $date ) = Today;
    $self->year     or $self->year(  $year );
    $self->month    or $self->month( $month );
    $self->date     or $self->date(  $date );
    eval{
        no warnings;
        die
            unless check_date( $self->year, $self->month, $self->date );
    };
    confess 'Invalid date: "'. $self->year .'-'. $self->month .'-'. $self->date .'"; ERROR: '. $@ 
        if $@;

    # template init
    $self->_template( Template->new )
        || die Template->error(), "\n";
    $self->template_extension || $self->template_extension( 'tt2' );
    $self->template_path      || $self->template_path( '.' );

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Month {
    my $self = shift;
    my( $month ) = @_;
    return Month_to_Text( $month || $self->month );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub days_in_month {
    my $self = shift;
    return Days_in_Month( $self->year, $self->month );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _process {
    my $self = shift;
    my( $template, $vars ) = @_;

    my $html = '';
    if( $self->vars ) {
        no warnings;
        $vars = { %$vars, %{ $self->vars }};
    }
    $self->_template->process( \$template, $vars, \$html )
        or die $self->_template->error, "\n";
    return $html;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub link {
    my $self = shift;
    my( $date, $href, $onclick ) = @_;

    return unless $date and $href;
    $onclick = $onclick
        ? { onclick => $onclick }
        : {};
    $self->links({ %{ $self->links || {} }, $date => { href => $href, %$onclick }});
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub class {
    my $self = shift;
    my( $date, $class ) = @_;

    return unless $date and $class;
    $class = $self->classes->{ $date } ." $class"
        if $self->classes and $self->classes->{ $date };

    $self->classes({ %{ $self->classes || {} }, $date => $class });
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub date_calc {
    my $self = shift;
    my( $calc ) = @_;

    my( $year, $month, $date ) = ( $self->year, $self->month, $self->date );
    if( defined $calc ) {
        $calc =~ /^(\D)?(\d+)([m])$/;
        my( $sign, $amount, $type ) = ( $1, $2, $3 );
        # print STDERR Dumper[ $sign, $amount, $type ];

        die 'Invalid calculation attempted.  See module.  sign: '. $sign
            if $sign and not ( $sign eq '+' or $sign eq '-' );
        die 'Invalid calculation attempted.  See module.  type:'. ( $type || '' )
            unless $type;

        $amount = $amount * -1
            if $sign and $sign eq '-';
        ( $year, $month, $date ) = Add_Delta_YM(
            $year, $month, $date,
            0, $amount,
        );
    }
    return {
        year    => $year,
        month   => $month,
        date    => $date,
        day     => $date,
        Month   => $self->Month( $month ),
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_weeks {
    my $self = shift;

    my @weeks = split /\n/ => Calendar( $self->year, $self->month, $self->orthodox ? 1 : 0 );

    # this will barf badly if the return from Calendar change
    # here's a sanity check.  side effect: trims useless lines
    die 'Calendar format not recognized'
        unless shift @weeks eq ''                   # first blank line
           and ( shift @weeks ) =~ /^\s+\w+\s+\d+/  # "    January 2006"
           and ( shift @weeks ) =~ /^\w+\s+\w+\s+/; # "Mon Tue ..."

    my @month;
    for( @weeks ) {
        $_ =~ s/^\s+//;
        my @week = split /\s+/ => $_;
        push @month => \@week;
    }
    # pad first week
    unshift @{ $month[ 0 ]} => 0
        for 1 .. ( 7 - scalar @{ $month[ 0 ]});
    # pad last week
    push @{ $month[ -1 ]} => 0
        for 1 .. ( 7 - scalar @{ $month[ -1 ]});

    return \@month;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _build_calendar {
    my $self = shift;
    my( $weeks ) = @_;

    $weeks ||= $self->_get_weeks;
    my $links = $self->links || {};
    my $classes = $self->classes || {};
    for( 1 .. @$weeks ) {
        for( @{ $weeks->[ $_ - 1 ]}) {
            my $date = $_;
            $_ = { date => $date };
            $_->{ link } = $links->{ $date }
                if defined $links->{ $date };
            $_->{ class } = $classes->{ $date }
                if defined $classes->{ $date };
        }
    }
    return $weeks;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub calendar {
    my $self = shift;

    my $template = '[%- INCLUDE calendar_calendar %]'
        . $self->_get_template( 'calendar' )
        . $self->_get_template( 'head' )
        . $self->_get_template( 'body' )
        . $self->_get_template( 'weeks' )
        . $self->_get_template( 'week' )
        . $self->_get_template( 'day' )
        ;

    return $self->_process( $template, {
        month       => $self->Month,
        year        => $self->year,
        weeks       => $self->_build_calendar,
        Calendar    => $self,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _get_template {
    my $self = shift;
    my( $name ) = @_;

    return unless $name;
    my $template;

    my @path = ref $self->template_path eq 'ARRAY'
        ? @{ $self->template_path }
        : $self->template_path;

    my ( $file ) = grep { -e } map {
        File::Spec->catfile(
            $_, $name . '.' . $self->template_extension
        )
    } @path;

    if ( $file ) {
        $template = do { local( @ARGV, $/ ) = $file ; <> } ;
    }
    else {
        $template = $self->_default_template( $name );
    }
    return unless $template;
    chomp $template;

    return <<EOT;
[%- BLOCK calendar_$name %]
$template
[%- END %]
EOT
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _default_template {
    my $self = shift;
    my( $name ) = @_;

    return unless $name;
    $name =~ /^calendar$/ and return <<EOT;
<table class="calendar">
[% INCLUDE calendar_head %]
[% INCLUDE calendar_body %]
</table>
EOT

    $name =~ /^head$/ and not $self->orthodox and return <<EOT;
    <thead>
        <tr>
            <th colspan="7">[% month %] [% year %]</th>
        </tr>
        <tr>
            <th>M</th>
            <th>Tu</th>
            <th>W</th>
            <th>Th</th>
            <th>F</th>
            <th>S</th>
            <th>S</th>
        </tr>
    </thead>
EOT

    $name =~ /^head$/ and $self->orthodox and return <<EOT;
    <thead>
        <tr>
            <th colspan="7">[% month %] [% year %]</th>
        </tr>
        <tr>
            <th>S</th>
            <th>M</th>
            <th>Tu</th>
            <th>W</th>
            <th>Th</th>
            <th>F</th>
            <th>S</th>
        </tr>
    </thead>
EOT

    $name =~ /^body$/ and return <<EOT;
    <tbody>
[% INCLUDE calendar_weeks %]
    </tbody>
EOT

    $name =~ /^weeks$/ and return <<EOT;
[%- FOR week IN weeks %]
[%- INCLUDE calendar_week %]
[%- END %]
EOT

    $name =~ /^week$/ and return <<EOT;
        <tr>
            [%- FOR day IN week %]
            [%- INCLUDE calendar_day %]
            [%- END %]
        </tr>
EOT

    $name =~ /^day$/ and return <<'EOT';
            [%- class = ' class="'_ day.class _'"' IF day.class %]
            [%- href = ' href="'_ day.link.href _'"' IF day.link.href %]
            [%- onclick = ' onclick="'_ day.link.onclick _'"' IF day.link.onclick %]
            <td[% class %]>[% "<a$href$onclick>" IF href || onclick %][% day.date IF day.date %][% '</a>' IF href || onclick %]</td>
EOT

    return;
}


1;

__END__

=head1 NAME

HTML::Calendar::Template - Generate semantic HTML calendar.

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use HTML::Calendar::Template;

    $month = HTML::Calendar::Template->new;
    # -- or -- #
    $month = HTML::Calendar::Template->new(
        year    => 2006,
        month   => 4,
        date    => 1,
    );

    print $month->calendar;

    ## links
    for( 1 .. $month->days_in_month ) {
        $month->link( $_, '?date='. $_ );
    }
    print $month->calendar;  # with each month a link

=head1 DESCRIPTION

HTML::Calendar::Template generates HTML for a single month's calendar.  Its goals are:

=over 4

=item * Minimal, valid, semantic markup.

=item * No presentation in markup.

=item * Good hooks for CSS stylin'.

=item * Easy to add content to cells.

=item * Easy to create new templates to replace the default.

=back

=head1 METHODS, Accessor

All accessor methods can be set either in the constructor or afterwards.  Each time a calendar is generated it uses the current value of these methods.  For instance:

    my $month = HTML::Calendar::Template->new(
        orthodox    => 1,
    );
    print $month->calendar; # prints calendar with Sunday as the start of week

    $month->orthodox( 0 );
    print $month->calendar; # prints calendar with Monday as the start of week

=head2 year

Optional, integer, default today.  Returns or sets year.

=head2 month

Optional, integer 1-12, default today.  Returns or sets month.

=head2 date

Optional, integer, default today.  Returns or sets date.

=head2 orthodox

Optional, 1 or 0, default 0.  An B<orthodox> calendar is one in which weeks start on Sunday.  By default, weeks start on Monday.

=head2 template_path

Optional, scalar, no default value.  Path to template directory.

=head2 template_extension

Optional, scalar, default: C<tt2>.  Extension for template files.

=head1 METHODS, Calendar Generation

=head2 link( $date, $href [, $onclick] )

Add an anchor tag to a single calendar day.

=head2 class( $date, $class )

Add a style class to a single calendar day.  Note that this is additive -- multiple calls to C<class> for the same date will provide multiple classes, like this:

    $month->class( 1, 'one' );
    # <td class="one">

    $month->class( 1, 'two' );
    # <td class="one two">

=head2 vars( %vars )

Additional variables to pass to the calendar templates.

=head2 calendar

Returns HTML calendar for current month.

=head1 METHODS, Utility

Utility methods aren't directly related to calendar generation.

=head2 Month([ $month ])

Return month as text string.  Given an optional integer between 1 and 12, returns month name associated with that integer.  Uses L<Date::Calc>'s C<Month_to_Text> internally, which supports many languages.  See L<Date::Calc>'s documentation for more information.

=head2 days_in_month

Returns number of days in the current month as an integer.

=head2 date_calc( $delta )

Returns year, month, date of current calendar munged by $delta.  Right now supports only month arithmetic.

    ( $year, $month, $date ) = $calendar->date_calc( '+3m' );
    ( $year, $month, $date ) = $calendar->date_calc( '-1m' );

=head1 METHODS, Internal

=head2 template

Returns the Template object.

=head2 links

Sets and returns the list of day links.

=head2 classes

Sets and returns the list of day classes.

=head2 init

Object initializer.

=head2 fields

List of accessors to create automagically.

=head1 AUTHOR

Randall Hansen, C<legless at cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-calendarmonthtemplate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=html-calendarmonthtemplate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=head1 COPYRIGHT & LICENSE

Copyright 2006 Randall Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

