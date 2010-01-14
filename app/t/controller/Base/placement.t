# Copyright (C) 2004-2007 OpenSourcery, LLC
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.  See eleMentalClinic::Base for more information.
#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 69;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use eleMentalClinic::Test;

our ($CLASS, $one, $tmp, $tmp_b, $tmp_c);
BEGIN {
    *CLASS = \'eleMentalClinic::Controller::Base::Placement';
    use_ok( q/eleMentalClinic::Controller::Base::Placement/ );
}

{
    package jeBlah;

    sub new {
        my $proto = shift;
        my( $args, $options ) = @_;
        my $class = ref $proto || $proto;
        my $self = bless {}, $class;
    }

    sub discharge {
        return 'inexplicable';
    }
}
        
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dbinit {
    $test->db_refresh;
    shift and $test->insert_data;
}
dbinit( 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# constructor
    ok( $one = $CLASS->new );
    ok( defined( $one ));
    ok( $one->isa( $CLASS ));

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# runmodes
    can_ok( $CLASS, 'ops' );
    ok( my %ops = $CLASS->ops );
    is_deeply( [ sort keys %ops ], [ sort qw/
        home change
        referral_edit referral_save
        admit_from_referral
        discharge discharge_view discharge_save_for_later discharge_commit
        readmit readmit_confirm
        event_edit event_save
    /]);
    can_ok( $CLASS, $_ ) for qw/
        home change
        referral_edit referral_save
        admit_from_referral
        discharge discharge_view discharge_save_for_later discharge_commit
        readmit readmit_confirm
        event_edit event_save
    /;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# home
    # home, no parameters

    ok( $one = $CLASS->new_with_cgi_params());
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->home );
    is( ref( $tmp->{ referrals_list }->[0] ), 'eleMentalClinic::Rolodex' );

    # home, parameters

    ok( $one = $CLASS->new_with_cgi_params());
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->home( undef, {
        firemen =>  {
            have_suits  =>  1,
            are_big     =>  1,
            department  =>  'FD',
            people      =>  [qw/
                Joe Carl William Frank
                Bob Bobby Billy
                John Elaine Jack
            /],
        }
    }));
    is( ref( $tmp->{ referrals_list }->[0] ), 'eleMentalClinic::Rolodex' );
    is_deeply( $tmp->{ firemen }, {
        have_suits  =>  1,
        are_big     =>  1,
        department  =>  'FD',
        people      =>  [qw/
            Joe Carl William Frank
            Bob Bobby Billy
            John Elaine Jack
        /],
    });

    # home, parameters and client, whatever it does

    ok( $one = $CLASS->new_with_cgi_params());
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->home( 1001, {
        firemen =>  {
            have_suits  =>  1,
            are_big     =>  1,
            department  =>  'FD',
            people      =>  [qw/
                Joe Carl William Frank
                Bob Bobby Billy
                John Elaine Jack
            /],
        }
    }));
    is( ref( $tmp->{ referrals_list }->[0] ), 'eleMentalClinic::Rolodex' );
    is_deeply( $tmp->{ firemen }, {
        have_suits  =>  1,
        are_big     =>  1,
        department  =>  'FD',
        people      =>  [qw/
            Joe Carl William Frank
            Bob Bobby Billy
            John Elaine Jack
        /],
    });

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# readmit
    # readmit, no parameters

    ok( $one = $CLASS->new_with_cgi_params( op => 'readmit' ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->readmit );
    is( ref( $tmp->{ referrals_list }->[0] ), 'eleMentalClinic::Rolodex' );
    is( $tmp->{ readmit_confirm }, 1 );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# discharge_view
    # discharge_view, no parameters

    ok( $one = $CLASS->new_with_cgi_params(
        op          =>  'discharge_view',
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->discharge_view );
    is_deeply( $tmp, {
        placement               =>  undef,
        discharge               =>  undef,
        last_contact_date_guess =>  undef,
    });

    # discharge_view, parameters

    ok( $one = $CLASS->new_with_cgi_params(
        op          =>  'discharge_view',
        client_id   =>  1002,
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->discharge_view );
    is( $tmp->{ discharge }, undef );
    is( $tmp->{ last_contact_date_guess }, '2005-07-18' );
    is( ref( $tmp->{ placement }), 'eleMentalClinic::Client::Placement' );
    is( ref( $tmp->{ placement }->{ event }), 'eleMentalClinic::Client::Placement::Event' );

    # discharge_view, parameters plugin parameters

    ok( $one = $CLASS->new_with_cgi_params(
        op          =>  'discharge_view',
        client_id   =>  1002,
    ));
    isa_ok( $one, $CLASS );

    ok( $tmp = $one->discharge_view( 'purploe' ) );
    is( $tmp->{ discharge }, 'purploe' );
    is( $tmp->{ last_contact_date_guess }, '2005-07-18' );
    is( ref( $tmp->{ placement }), 'eleMentalClinic::Client::Placement' );
    is( ref( $tmp->{ placement }->{ event }), 'eleMentalClinic::Client::Placement::Event' );

    # discharge_view, parameters plugin parameters fake placement

    ok( $one = $CLASS->new_with_cgi_params(
        op          =>  'discharge_view',
        client_id   =>  1002,
    ));
    isa_ok( $one, $CLASS );

        $one->{ placement } = 'trianglees';

    ok( $tmp = $one->discharge_view( 'purploe' ) );
    is( $tmp->{ discharge }, 'purploe' );
    is( $tmp->{ last_contact_date_guess }, '2005-07-18' );
    is( $tmp->{ placement }, 'trianglees' );

    # discharge_view, parameters plugin parameters better fake placement

    ok( $one = $CLASS->new_with_cgi_params(
        op          =>  'discharge_view',
        client_id   =>  1002,
    ));
    isa_ok( $one, $CLASS );

        $one->{ placement } = jeBlah->new;

    ok( $tmp = $one->discharge_view );
    is( $tmp->{ discharge }, 'inexplicable' );
    is( $tmp->{ last_contact_date_guess }, '2005-07-18' );
    is( ref $one->{ placement }, 'jeBlah' );


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dbinit();

