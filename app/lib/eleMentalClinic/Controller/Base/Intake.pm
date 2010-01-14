package eleMentalClinic::Controller::Base::Intake;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Controller::Default::Intake

=head1 SYNOPSIS

Intake Controller.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::CGI /;
use eleMentalClinic::Client;
use eleMentalClinic::Client::Assessment;
use eleMentalClinic::Client::Placement;
use eleMentalClinic::Client::Intake;
use eleMentalClinic::Client::Referral;
use eleMentalClinic::Contact::Address;
use eleMentalClinic::Contact::Phone;
use Carp;

our @INTAKE_STEPS = ( qw/
    Personal
    Contact
    Demographics
    Medical
    Placement
/);

#Putting this list here to ensure we clear all the intake wizards session data.
my @WIZARD_SESSION_PARAMS = qw/ presenting_problem special_needs medications /;

use constant DEPARTMENT_ID          => 1001;
use constant MAX_ADDRESSES          => 3;
use constant MAX_PHONES             => 3;
use constant MAX_EMERGENCY_CONTACTS => 3;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;

    $self->SUPER::init( $args );
    $self->template->vars({
        styles => [ qw/ intake date_picker /],
        script => 'intake.cgi',
        intake_steps => \@INTAKE_STEPS,
        javascripts  => [ 'intake.js' ],
        use_new_date_picker => 1,
        MAX_ADDRESSES          => MAX_ADDRESSES,
        MAX_PHONES             => MAX_PHONES,
        MAX_EMERGENCY_CONTACTS => MAX_EMERGENCY_CONTACTS,
    });

    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub ops {
    (
        home => {},
        step1 => {},
        step1_save => {
            -on_error   => 'step1',
            lname   => [ 'Last name', 'required', 'text::liberal', 'length(0,25)' ],
            mname   => [ 'Middle name', 'text::words', 'length(0,15)' ],
            fname   => [ 'First name', 'required', 'text::words', 'length(0,25)' ],
            ssn     => [ 'Social Security number', 'demographics::us_ssn(integer)' ],
            dob     => [ 'Birth date', 'required', 'date::iso(past)' ],
            sex     => [ 'Sex', 'required', 'text::word' ],
            event_date  => [ 'Admit date', 'date::iso' ],
        },
        step2 => {},
        step2_save => {
            -on_error => 'step2',
            email => [ "E-Mail Address", 'email' ],
            no_address   => [ 'No Address', 'checkbox::boolean' ],
            no_phone     => [ 'No Phone', 'checkbox::boolean' ],
            no_emergency => [ 'No Emergency', 'checkbox::boolean' ],
            # addresses
            client_address => {
                -construct_object => 'eleMentalClinic::Contact::Address',
                address1 => [ 'Address Line 1', 'alternative(no_address)' ],
                address2 => [ 'Address Line 2' ],
                city     => [ 'Address City', 'alternative(no_address)' ],
                state    => [ 'Address State', 'alternative(no_address)', 'demographics::us_state2' ],
                post_code => [ 'Address Zip Code', 'alternative(no_address)', 'number::integer' ],
                county    => [ 'Address County' ],
                active    => [ 'Address Active', 'checkbox::boolean' ],
            },
            # phones
            client_phone => {
                -construct_object   => 'eleMentalClinic::Contact::Phone',
                phone_number    => [ 'Phone Number', 'alternative(no_phone)', 'length(0,18)' ],
                phone_type      => [ 'Phone Type' ],
                call_ok         => [ 'Call Ok', 'checkbox::boolean' ],
                message_ok      => [ 'Message Ok', 'checkbox::boolean' ],
                active          => [ 'Active', 'checkbox::boolean' ],
            },
            # emergency contact
            client_emergency_contact => {
                lname           => [ "Emergency Contact Last Name", 'length(0,25)', 'alternative(no_emergency)' ],
                fname           => [ "Emergency Contact First Name", 'length(0,25)', 'alternative(no_emergency)' ],
                phone_number    => [ "Emergency Contact Phone #", 'alternative(no_emergency)', 'length(0,18)' ],
                comment_text    => [ "Emergency Contact Relationship", 'alternative(no_emergency)' ],
            },
            client_address_primary   => [ 'Primary Address' ],
            client_phone_primary     => [ 'Primary Phone' ],
        },
        step3 => {},
        step3_save => {
            -on_error => 'step3',
            name => [ 'Employer Name', 'alternative(no_employment)' ],
            no_employment => [ 'No Employer', 'checkbox::boolean' ],
            client_employer => {
                -max_objects => 1,
                job_title  => [ 'Occupation' ],
                supervisor => [ 'Supervisor' ],
            },
            client_employer_phone => {
                -max_objects => 1,
                -construct_object => 'eleMentalClinic::Contact::Phone',
                phone_number    => [ 'Phone Number', 'alternative(no_employment)' ],
                phone_type      => [ 'Phone Type'   ],
                call_ok         => [ 'Call Ok',    'checkbox::boolean' ],
                message_ok      => [ 'Message Ok', 'checkbox::boolean' ],
                active          => [ 'Active',     'checkbox::boolean' ],
            },
            client_employer_address => {
                -max_objects => 1,
                -construct_object => 'eleMentalClinic::Contact::Address',
                address1 => [ 'Address Line 1' ],
                address2 => [ 'Address Line 2' ],
                city     => [ 'Address City' ],
                state    => [ 'Address State' ],
                post_code => [ 'Address Post Code' ],
                county    => [ 'Address County' ],
            },
            client => {
                -max_objects => 1,
                household_annual_income => [ 'Annual Income', 'number::positive_int' ],
                household_population => ['Population', 'number::positive_int' ],
                household_population_under18 => [ 'Population Under 18', 'number::positive_int' ],
                dependents_count => [ '# of dependents', 'number::positive_int' ],
                edu_level        => [ 'Education Level' ],
                marital_status   => [ 'Marital Status'  ],
                race             => [ 'Ethnicity' ],
                religion         => [ 'Religion' ],
                language_spoken  => [ 'Language Spoken' ],
                nationality_id   => [ 'Nationality', 'required', 'number::integer' ],
                chart_id         => [ 'Chart #', 'length(0,16)' ],
            }
        },
        step4 => {},
        step4_save => {
            -on_error => 'step4',
            field => {
                template_field_id  => [ 'Template Field ID' ],
                value        => [ 'Field Value' ],
            },
            client_primary_treater => {
                -max_objects => 1,
                name => [ 'Name' ],
                lname => [ 'Last name', 'length(0,25)', 'alternative(no_treater)' ],
                fname => [ 'First name', 'length(0,25)', 'alternative(no_treater)' ],
            },
            client_primary_treater_phone => {
                -max_objects => 1,
                -construct_object => 'eleMentalClinic::Contact::Phone',
                phone_number => [ 'Phone Number' ],
            },
            client_primary_treater_address => {
                -max_objects => 1,
                -construct_object => 'eleMentalClinic::Contact::Address',
                address1 => [ 'Address Line 1' ],
                address2 => [ 'Address Line 2' ],
                city     => [ 'Address City' ],
                state    => [ 'Address State' ],
                post_code => [ 'Address Post Code' ],
            },
        },
        step5 => { },
        step5_save => {
            program_id       => [ 'Program', 'required' ],
            event_date       => [ 'Event Date', 'required' ],
            staff_id         => [ 'Staff Member' ],
            level_of_care_id => [ 'Level of Care ID' ],
            is_referral      => [ 'Is a Referral', 'required' ],
            rolodex_id       => [ 'Referral Source', 'required_if(is_referral)' ],
            agency_type      => [ 'Referral Agency Type' ],
            agency_contact   => [ 'Referral Agency Contact' ],
        },
        # AJAX
        _address => {},
        _phone => {},
        _emergency_contact => {},
    )
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _address {
    my $self = shift;

    $self->ajax( 1 );
    return {
        prefix              => 'client_address',
        ordinal             => $self->param( 'ordinal' ),
        locally_required    => 1,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _phone {
    my $self = shift;

    $self->ajax( 1 );
    return {
        prefix              => 'client_phone',
        ordinal             => $self->param( 'ordinal' ),
        locally_required    => 1,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _emergency_contact {
    my $self = shift;

    $self->ajax( 1 );
    return {
        prefix              => 'client_emergency_contact',
        ordinal             => $self->param( 'ordinal' ),
        locally_required    => 1,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step1 {
    my $self = shift;
    my( $client, $duplicates, $dups_ok ) = @_;

    croak 'Client must be a hashref or a ::Client object'
        if $client and not ref $client;

    $client = $self->client
        if not $client and $self->client->id;
    $client ||= { $self->Vars };

    $duplicates = $self->expand_duplicates( $duplicates ) if $duplicates;

    return {
        step        => 1,
        client      => $client, # XXX this is necessary here, but for no other step
        dupsok      => $dups_ok || 0,
        duplicates  => $duplicates || 0,
    };
}

sub expand_duplicates {
    my $self = shift;
    my ( $original ) = @_;
    my $new = {};

    $new->{ ssn } = $self->client_if_allowed( $original->{ ssn } );
    push @{ $new->{lname_dob} } => $self->client_if_allowed( $_ )
        for @{ $original->{lname_dob}};
    push @{ $new->{lname_fname} } => $self->client_if_allowed( $_ )
        for @{ $original->{lname_fname}};

    return $new;
}

sub client_if_allowed {
    my $self = shift;
    my ( $data ) = @_;
    my $client_id = $data->{ client_id };
    return unless $client_id;

    if (
        $self->current_user &&
        !$self->current_user->primary_role->has_client_permissions( $client_id )
    ) {
        my $lname = ucfirst( lc( $data->{ lname } ));
        my $fname = ucfirst( lc( $data->{ fname } ));
        my $dob = $data->{ dob };
        $lname =~ s/[a-z]/x/g;
        $fname =~ s/[a-z]/x/g;
        $dob =~ s/^\d{4}/xxxx/g;
        return {
            denied => 1,
            lname => $lname,
            fname => $fname,
            dob => $dob,
        }
    };

    return eleMentalClinic::Client->retrieve( $client_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step1_save {
    my $self = shift;

    my $client = $self->client;
    my $step = $client->intake_step || 1;

#        unless $client->intake_step and $client->intake_step > $step;

    foreach my $param (qw(lname mname fname ssn dob sex event_date birth_name)) {
        $client->$param($self->param($param)) if $self->param($param);
    }

    my $duplicates = $client->dup_check;

    if( $duplicates->{ ssn }) {
        return $self->step1( $client, $duplicates, 'dups_ok' );
    }
    elsif( not $client->id and $duplicates->{ lname_dob } and ! $self->param( 'dupsok' )) {
        return $self->step1( $client, $duplicates, 'dups_ok' ); 
    }
    else {
        $client->intake_step( $step );
        $client->update( {$self->Vars} );
        $self->current_user->primary_role->grant_client_permissions( $client->id )
            if $self->current_user;

        # redirect to intake_step?
        return $self->_redirect_to_step( ++$step, { client_id => $client->id } );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step2 {
    my $self = shift;
    my( $args ) = @_;

    my $client_id = $args->{ client_id }
        if $args;
    my $client = $self->client( $client_id );
    
    # Do not remove the check for objects. This is how the number of objects that have
    # been entered is found if step2_save has an error.
    my $addresses_count = 1;
    if( @{ $self->objects( 'client_address' )}) {
        $addresses_count = @{ $self->objects( 'client_address' )};
    }
    elsif( @{ $client->addresses }) {
        $addresses_count = @{ $client->addresses };
    }

    my $phones_count = 1;
    if( @{ $self->objects( 'client_phone' )}) {
        $phones_count = @{ $self->objects( 'client_phone' )};
    }
    elsif( @{ $client->phones }) {
        $phones_count = @{ $client->phones };
    }
    
    my $emergency_count = 1;
    if( @{ $self->objects( 'client_emergency_contact' )}) {
        $emergency_count = @{ $self->objects( 'client_emergency_contact' )};
    }
    elsif( @{ $client->get_emergency_contacts || [] }) {
        $emergency_count = @{ $client->get_emergency_contacts };
    }

    # Set to the value from param if it exists.
    my $no_address = $self->param( 'no_address' );
    my $no_phone = $self->param( 'no_phone' );
    my $no_emergency = $self->param( 'no_emergency' );

    # If we have already moved beyond here and are comming back to it we
    # need to determine the status of the no_XXX vars.
    if ( $self->client->intake_step and $self->client->intake_step > 1 ) {
        $no_address = 1 unless $self->client->addresses->[0];
        $no_phone = 1 unless $self->client->phones->[0];
        $no_emergency = 1 unless $self->client->get_emergency_contacts;
    }

    return {
        step    => 2,
        client  => $client,
        client_addresses_count => $addresses_count,
        client_phones_count => $phones_count,
        client_emergency_count => $emergency_count,
        no_address   => $no_address || 0,
        no_phone     => $no_phone || 0,
        no_emergency => $no_emergency || 0,
    };
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# helper method to save contacts which have a consistent interface.
sub save_client_contacts {
    my $self = shift;
    my ($type, $client_id) = @_;

    for (my $i = 0; $i < @{$self->objects($type)}; $i++) {
        my $obj = $self->objects($type)->[$i];
        $obj->client_id($client_id);
        $obj->primary_entry(1) if ($i eq $self->param($type."_primary"));
        $obj->save;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step2_save {
    my $self = shift;

    my $step = 2;

    # save client records
    my $client = $self->client;
    my $client_id = $client->id;

    $client->email($self->param('email'));

    #1215 - need to be able to clear values
    if ( $self->param( 'no_address' ) and $client->addresses->[0] ) {
        $_->delete for @{ $client->addresses };
    }
    if ( $self->param( 'no_phone' ) and $self->client->phones->[0] ) {
        $_->delete for @{ $self->client->phones };
    }
    if ( $self->param( 'no_emergency' ) and $self->client->get_emergency_contacts ) {
        $_->delete for @{ $self->client->get_emergency_contacts };
    }

    $self->save_client_contacts('client_address', $client_id) unless ( $self->param( 'no_address' ));
    $self->save_client_contacts('client_phone', $client_id) unless ( $self->param( 'no_phone' ));

    # emergency contacts are a hash, not an object.
    my $emergency_contact = $self->objects('client_emergency_contact');
    $client->save_emergency_contacts($emergency_contact) unless ( $self->param( 'no_emergency' ));

    $client->intake_step($step);
    $client->save;
    return $self->_redirect_to_step( ++$step, $self->client );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_employer {
    my $self = shift;

    return $self->client->relationship_primary('employment');
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step3 {
    my $self = shift;
    my ($args) = @_;

    my $no_employment = 0;

    if (
        ($self->client->intake_step || 0) >= 3 # XXX not sure if this is the desired behavior
        && !$self->get_employer 
    ) {
        $no_employment = 1;
    }

    return {
        step    => 3,
        client  => $self->client($args->{client_id}),
        no_employment => $no_employment,
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step3_save {
    my $self = shift;

    my $step = 3;
    my $vars = $self->Vars;

    my $client = $self->client;

    if ($self->param('no_employment')) { 
        # ensure there's no active relationship

        my $employer = $self->get_employer;
        if ($employer) {
            $employer->update( { active => 0 } );
        }
    } 
    else {

        my $employer = $self->get_employer;
        my $rolodex;
        
        if ( $employer ) {
            $rolodex = $employer->rolodex;
            $rolodex->name($vars->{name});
            $rolodex->save;
        }
        else {
            $rolodex = eleMentalClinic::Rolodex->new;
            $rolodex->dept_id(DEPARTMENT_ID);
            $rolodex->name($vars->{name});
            $rolodex->save;
            $rolodex->add_role('employment');

            my $rel_id = $client->rolodex_associate(
                'employment',
                $rolodex->id,
            );

            $employer = $client->relationship_getone({
                    role => 'employment',
                    relationship_id => $rel_id,
                }
            );
        }

        my $employment = $self->objects('client_employer')->[0];
        $employer->update($employment);

        foreach my $address (@{$self->objects('client_employer_address')}) {
            $address->rolodex_id($rolodex->id);
            $address->active(1);
            $address->save; 
        }

        foreach my $phone (@{$self->objects('client_employer_phone')}) {
            if ($phone->phone_number) {
                $phone->rolodex_id($rolodex->id);
                $phone->active(1);
                $phone->save;
            }
        }
    }

    $client->update( { %{$self->objects('client')->[0]}, intake_step => $step } );

    return $self->_redirect_to_step( ++$step );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step4 {
    my $self = shift;
    my ($args) = @_;

    my $active = eleMentalClinic::Client::AssessmentTemplate->get_intake();
    $active = $active->id if $active;

    my $out = {};
    if ( $active ) {
        my $assessment = $self->client->assessment;
        $assessment ||= eleMentalClinic::Client::Assessment->new({
            client_id => $self->get_client->id, 
            template_id => $active,
        });
        $out = {
            current_assessment => $assessment,
            fields  => $assessment->all_fields,
        }
    }

    my $vars = $self->template->vars;
    push @{$vars->{ styles }}, 'configurable_assessment', 'feature/selector', 'gateway';
    push @{$vars->{ javascripts }}, qw/ configurable_assessment.js jquery.js /;

    return {
        step    => 4,
        client  => $self->client($args->{client_id}),
        %$out,
        no_treater => $self->client->intake_step > 3 &&
                      !$self->client->relationship_primary('treaters') 
                        ? 1
                        : 0,
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub save_treater {
    my $self = shift;
    my $vars = $self->Vars;
    my $client = $self->client;

    return if $self->param('no_treater');
    # If we have treater info we will want to save it.
    # Make sure we save an address if any address info is provided
    # Make sure we save a phone record if any phone info is provided
    return unless $self->objects('client_primary_treater')->[0] or
                  $self->objects('client_primary_treater_address')->[0] or
                  $self->objects('client_primary_treater_phone')->[0];

    # Throw an exception to protect against #1044
    my $info = $self->objects('client_primary_treater')->[0];
    die( "Address or phone number added to NULL treater" )
        unless $info && join( '', values %$info );

    # Get existing rolodex, or create a new one.
    my $relationship = $self->client->relationship_primary('treaters');
    my $rolodex = $relationship ? $relationship->rolodex
                                : eleMentalClinic::Rolodex->new;

    $rolodex->dept_id(DEPARTMENT_ID);
    $rolodex->update( $info );
    $rolodex->save;

    #Add the relationship if it is not already there.
    unless( $relationship ) {
        $rolodex->add_role('treaters');
        my $rel_id = $client->rolodex_associate(
            'treaters',
            $rolodex->id,
        );
    }

    for my $address (@{$self->objects('client_primary_treater_address')}) {
        $address->rec_id($rolodex->addresses->[0]->rec_id) if $rolodex->addresses->[0];
        $address->rolodex_id($rolodex->id);
        $address->active(1);
        $address->save;
    }

    for my $phone (@{$self->objects('client_primary_treater_phone')}) {
        next unless join( '', values %$phone );
        $phone->rec_id($rolodex->phones->[0]->rec_id) if $rolodex->phones->[0];
        $phone->rolodex_id($rolodex->id);
        $phone->active(1);
        $phone->save;
    }
}

sub step4_save {
    my $self = shift;

    my $step = 4;
    my $vars = $self->Vars;
    my $client = $self->client;

    $self->save_treater;

    my $active = eleMentalClinic::Client::AssessmentTemplate->get_intake();
    $active = $active->id if $active;
    if ( $active ) {
        eleMentalClinic::Client::Assessment->create_or_update(
            start_date => $self->param( 'start_date' ) || undef,
            end_date => $self->param( 'end_date' ) || undef,
            client_id => $self->get_client->id,
            template_id => $active,
            staff_id => $self->current_user->staff_id,
            rec_id => $self->param( 'assessment_id' ) || undef,
            fields => $self->objects( 'field' ) || [],
        );
    }

    $self->client->update({ intake_step => $step });
    return $self->_redirect_to_step( ++$step );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step5 {
    my $self = shift;

    $self->override_template_name( 'step5' );
    return {
        step => 5,
        referrals_list  => eleMentalClinic::Rolodex->new->get_byrole( 'referral' ) || [],
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub step5_save {
    my $self = shift;

    return $self->step5 if $self->errors;

    my $step = 5;
    my $vars = $self->Vars;

    my $client = $self->client;

    $client->placement->change(
        dept_id            => DEPARTMENT_ID,
        program_id         => $vars->{program_id},
        event_date         => $vars->{event_date},
        level_of_care_id   => $vars->{level_of_care_id},
        staff_id           => $vars->{staff_id},
        active             => 1,
        intake_id          => 1,
    );

    my $event = $self->client->placement->event;
    my $assessment = eleMentalClinic::Client::Assessment->get_all_by_client( $self->client->id )->[0];
    my $intake = eleMentalClinic::Client::Intake->new({
        client_id => $self->client->id,
        client_placement_event_id => $event->rec_id,
        assessment_id => $assessment ? $assessment->id : undef,
    });
    $intake->save;
    $event->intake_id( $intake->id );
    $event->save;

    if ( $self->param( 'is_referral' )) {
        eleMentalClinic::Client::Referral->new({
            client_id                 => $self->client->client_id,
            rolodex_referral_id       => $self->param( 'rolodex_id' ), 
            agency_type               => $self->param( 'agency_type' ),
            agency_contact            => $self->param( 'agency_contact' ),
            active                    => 1,
            client_placement_event_id => $self->client->placement->event->rec_id,
        })->save;
    }

    $self->client->update({ intake_step => undef });

    for my $param ( @WIZARD_SESSION_PARAMS ) {
        $self->session->param( "$param-" . $client->id, undef );
    }

    return( '', { Location => "/demographics.cgi?client_id=". $client->id });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub intake_params {
    my $self = shift;
    return { 
        map { 
            $_ => $self->session->param( "$_-" . $self->client->id )
        } @WIZARD_SESSION_PARAMS 
    };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub home {
    my $self = shift;
    my( $client, $duplicates, $dupsok ) = @_;

    $client ||= 0;
    $duplicates ||= 0;
    $dupsok ||= 0;

    if( $client ) {
        $client->{ program_id } = $self->program_id;
    }
    $self->template->vars({
        styles => [ 'layout/5050', 'gateway', 'intake', 'date_picker' ],
    });
    $self->template->process_page( 'intake/step1', {
        client      => $client,
        dupsok      => $dupsok,
        duplicates  => $duplicates,
    });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub program_id {
    my $self = shift;

    return $self->param( 'admission_program_id' )
        if ($self->param( 'intake_type' ) || '') eq 'Admission';
    return $self->param( 'referral_program_id' )
        if ($self->param( 'intake_type' ) || '') eq 'Referral';
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _redirect_to_step {
    my $self = shift;
    my( $step, $args ) = @_;

    $args ||= { client_id => $self->client->id };

    return $self->forward("step$step", $args);
}


'eleMental';

__END__

=head1 AUTHORS

=over 4

=item Chad Granum L<chad@opensourcery.com>

=item Randall Hansen L<randall@opensourcery.com>

=item Erik Holensbe L<erikh@opensourcery.com>

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
