# vim: ts=4 sts=4 sw=4
package Earth::t::Mechanize::Intake;
use strict;
use warnings;
use Test::More;
use Earth::Mechanize;
use eleMentalClinic::Client;

my %STEP = (
    1 => {
        fname => 'First',
        lname => 'Last',
        mname => 'M',
        ssn   => '111-11-1112',
        sex   => 'Male',
        dob   => '2000-01-01',
    },
    2 => {
        no_emergency => 'on',
        no_address => 'on',
        no_phone => 'on',
    },
    3 => {
        no_employment => 'on',
    },
    4 => {
        no_treater => 'on',
        'field[1071][value]' => 'Wacky guy',
    },
    5 => {
        program_id => 1002, # Adolescent
    },
    '5_referral_incomplete' => {
        is_referral => 1,
    },
);

sub new {
    my $class = shift;
    return bless( {}, $class );
}

sub shuffle {
    my @steps = @_;
    return map { splice @steps, int(rand(@steps)), 1 } 1..@steps;
}

my @TESTS = (
# from IntakeWorkflow/UseCases
#
# One clinician, sequential, saves 
# 
#     * 1 clinician goes through intake in a sequential order and creates the patient. 
    one_straight_through => [
        qw(step2 step3 step4 step5)
    ],
# 
# One clinician, non-sequential, saves 
# 
#     * 1 clinician fills out first step
#     * Fills other workflow pages in a random order
#     * Saves patient 
    one_random => [
        shuffle(qw(step2 step3 step4 step5))
    ],
# 
# One clinician, sequential, browser crash 
# 
#     * 1 clinician fills out first step
#     * Fills out another workflow page
#     * Browser crashes
#     * Logs back in and pulls up partial intake
#     * Completes intake 

    one_interrupted => [
        qw(step2 logout partial step3 step4 step5)
    ],
 
# Two clinicians, non-sequential, no postpone 
# 
#     * 1 clinican fills outs the first step
#     * Fills out 1 other page of information
#     * Doesn't postpone intake, but closes browser
#     * 2nd clinican pulls up partial intake from "Partial Intake" on the home page
#     * Fills out the rest of the intake in random order
#     * Saves patient 

    two_interrupted => [
        qw(step2 switch partial), shuffle(qw(step3 step4 step5)),
    ],

# Two clinicians, non-sequential, postpone 
# 
#     * 1 clinican fills outs the first step
#     * Fills out 1 other page of information
#     * Postpones intake
#     * 2nd clinican pulls up partial intake from "Partial Intake" on the home page
#     * Fills out the rest of the intake in random order
#     * Saves patient 

    two_random_interrupted => [
        qw(step2 postpone switch partial), shuffle(qw(step3 step4 step5)),
    ],

# 1 clinician, tries to enter duplicate patient who already went through intake 
# 
#     * clinician fills out the first step but name or some other pieces of data are the same
#     * clinician should receive error message 
# 

    one_duplicate_complete => [
        qw(step2 step3 step4 step5 step1_duplicate_complete),
    ],

# 1 clinician, tries to enter duplicate patient who has a partial intake 
# 
#     * clinician fills out the first step but name or some other pieces of data are the same
#     * clinician should receive error message 
    
    one_duplicate_partial => [
        qw(step1_duplicate_partial),
    ],

# bonus test: bug #1182

    bug_1182 => [
        qw(step2 step3 step4 step5_referral_incomplete)
    ],
); 

sub run {
    my $self = shift;

    while ( my ($test_name, $test_steps) = splice @TESTS, 0, 2 ) {
        diag "test: $test_name";
        delete $self->{ ran_step_4 };
        my $mech = Earth::Mechanize->new_with_server;
        $mech->admin_login_ok;

        # we ALWAYS start with step1
        my $client_id = $self->step1( $mech );

        for my $step (@$test_steps) {
            $self->$step( $mech, $client_id );
        }
    }
}

sub get {
    my $self = shift;
    my ( $mech, $step, $client_id ) = @_;
    $mech->get_script_ok( 'intake.cgi',
        (
            op => "step$step",
            client_id => $client_id,
        )
    );
}

sub submit {
    my $self = shift;
    my ( $mech, $step ) = @_;
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $STEP{$step},
        },
        "submit step$step",
    );
}

sub at_least_to {
    my $self = shift;
    my ( $mech, $step ) = @_;
    my $div = $mech->look_down(id => 'progress');
    ok( $div, 'found id=progress' );
    my ($up_to) = $div->as_trimmed_text =~ /completed (\d) of the/;
    cmp_ok( $up_to, 'ge', $step, "completed at least step $step" )
        or diag $div->as_trimmed_text;
}

sub step1 {
    my $self = shift;
    my ( $mech ) = @_;
    $mech->get_script_ok( 'intake.cgi' );
    $self->submit( $mech, 1 );
    $self->at_least_to( $mech, 1 );
    my $client_id = $mech->look_down(_tag => 'input', id => 'client_id')
        ->attr('value');
    ok $client_id, 'found a client_id';
    return $client_id;
}

sub step2 {
    my $self = shift;
    my ( $mech, $client_id ) = @_;
    $self->get( $mech, 2, $client_id );
    $self->submit( $mech, 2 );
    $self->at_least_to( $mech, 2 );
}

sub step3 {
    my $self = shift;
    my ( $mech, $client_id ) = @_;
    $self->get( $mech, 3, $client_id );
    $self->submit( $mech, 3 );
    $self->at_least_to( $mech, 3 );
}

sub step4 {
    my $self = shift;
    my ( $mech, $client_id ) = @_;
    $self->get( $mech, 4, $client_id );
    $self->submit( $mech, 4 );
    $self->at_least_to( $mech, 4 );
    $self->{ ran_step_4 }++;
}

sub step5 {
    my $self = shift;
    my ( $mech, $client_id ) = @_;
    $self->get( $mech, 5, $client_id );
    $self->submit( $mech, 5 );
    is $mech->uri->path, '/demographics.cgi', 'completed client intake';
    my $intake = $mech->look_down( id => 'intake_assessment' );
    if( $self->{ ran_step_4 } ) {
        ok( $intake, "found #intake_assessment" ) or do {
            diag $mech->content_errors;
        };
    }
}

sub step5_referral_incomplete {
    my $self = shift;
    my ( $mech, $client_id ) = @_;
    $self->get( $mech, 5, $client_id );
    $self->submit( $mech, '5_referral_incomplete' );
    is $mech->uri->path, '/intake.cgi', 'still on intake';
    $mech->content_errors_contain( 'Referral Source is required.' );
}

sub postpone {
    my $self = shift;
    my ( $mech ) = @_;
    $mech->follow_link_ok({ text_regex => qr/postpone this intake/i });
}

sub logout {
    my $self = shift;
    my ( $mech ) = @_;
    $mech->cookie_jar( {} );
    $mech->admin_login_ok;
}

sub switch {
    my $self = shift;
    my ( $mech ) = @_;
    $mech->cookie_jar( {} );
    $mech->login_ok( 1, qw(ima imaima) );
}

sub partial {
    my $self = shift;
    my ( $mech ) = @_;
    $mech->follow_link_ok({
        text => "$STEP{1}{lname}, $STEP{1}{fname} $STEP{1}{mname}"
    });
}

sub step1_duplicate {
    my $self = shift;
    my ( $mech ) = @_;
    $self->get( $mech, 1 );
    $self->submit( $mech, 1);
    my $dupes = $mech->look_down( id => 'duplicates' );
    ok $dupes, 'found box for duplicates';
    return $dupes;
}

sub step1_duplicate_partial {
    my $self = shift;
    my ( $mech ) = @_;
    my $dupes = $self->step1_duplicate( $mech );
    like $dupes->as_trimmed_text, qr/in the middle of the intake process/,
        "found partial intake text";
}

sub step1_duplicate_complete {
    my $self = shift;
    my ( $mech ) = @_;
    my $dupes = $self->step1_duplicate( $mech );
    like $dupes->as_trimmed_text, qr/is currently admitted/,
        "found complete intake text";
}

1;
