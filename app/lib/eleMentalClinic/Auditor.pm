# Copyright (C) 2004-2006 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.

=pod

=head1 AUTHORS

The Auditor class provides a facade for logging audit trail entries.

Currently Auditor uses prognotes to record log entries.

An auditor must know on Who's behalf the log is being made, and What is to be logged.

An auditor if not supplied a current_user will look one up by instantiating a temporary CGI object.

FIXME I believe this model may break down once we move outside of per process CGI calls.  I'm concerned that a second creation of a CGI object might not have the same query parameters to work with, and thus dip into someone else's session?  This needs some experimentation.

=over 4

=item Josh Partlow L<jpartlow@opensourcery.com>

=back

=cut

package eleMentalClinic::Auditor;

use strict;
use warnings;
use Data::Dumper;
use eleMentalClinic::CGI;

use base qw/ eleMentalClinic::Base /;

# FIXME This is a hack to allow unit testing without the CGI calls which are difficult to set up the sesion for.  One way out of this would be a config setting for the class of Auditor to use, and a TestAuditor subclass that doesn't pester CGI for current_user.
our $Test_Current_User;

{
    sub methods { [ qw/ current_user / ] }
}

=head1 new() 

Constructs a new Auditor object.  Any Base arguments may be passed in, and a current_user references to a Personnel may also be passed in.  Otherwise current_user is set from CGI.

Accepts a single hashref or nothing for arguments.  If a current_user is to be passed in, it must be element current_user => $current_user ...

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my( $args ) = @_;

    die "Arguments to a new eleMentalClinic::Auditor must be a single hashref or nothing."
        unless not $args or ref $args eq 'HASH';

    my $self = $class->SUPER::new( 
        %$args
    );
    $self->current_user( 
        $args->{current_user} || 
        $Test_Current_User ||
        eleMentalClinic::CGI->new->current_user
    );
    die "No current user obtained." unless $self->current_user;

    return $self;
}

=head1 audit()

Enters a new log entry into the audit trail.

Expects a client_id, a header and a body.

Generates staff_id from the current_user, and adds timestamp.

Returns the record_id of the created row (currently a prognote entry).

=cut

sub audit {
    my $self = shift;
    my( $client_id, $header, $body ) = @_;

    die "Call to Auditor->log() with insufficient parameters."
        unless $client_id && $header && $body;

    #FIXME: Stripping time from timestamp in order to preserve sorting (date,
    #rec_id) for venus. Eventually we need a better solution, the alternative
    #is to save prognotes in the past w/ 23:59:59 and ones for today w/ an
    #actual timestamp, but thats more ugly atm.

    my $timestamp = $self->timestamp;
    $timestamp =~ s/^([\d-]+) .*/$1 00:00:00/;

    my $note = eleMentalClinic::ProgressNote->new( {
        client_id   => $client_id,
        staff_id    => $self->current_user->staff_id,
        goal_id     => 0,
        note_header => $header,
        note_body   => $body, 
        start_date  => $timestamp,
    });
    $note->commit;
    $note->save;

    return $note->id;
}

1;
