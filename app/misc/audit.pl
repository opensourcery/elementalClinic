#!/usr/bin/perl
use strict;
use warnings;

# Insurance audit script for eleMental Clinic
#
# Usage:
# ./audit --client_insurance [client_id]
#   show all active mental health insurers for a client
#
# ./audit --mental_health_insurance
#   show all active mental health insurers
#
# Additional arguments:
#   -- dump : dump data with Data::Dumper instead of formatting it
#
# Argument aliases
# "-ci" for "--client_insurance"
# "-mhi" for "--mental_health_insurance"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Audit;
use strict;
use warnings;
no warnings qw/ redefine /;

use lib qw# ../lib/ #;
use base qw/ eleMentalClinic::Base /;
use Data::Dumper;
use Getopt::Long;

$Data::Dumper::Sortkeys = 1;

my $EXCLUDE = join ',' => qw/
    1397 1398 2467
/;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub methods {[ qw/ options /]}
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;

    $self->SUPER::init;

    my %options;
    my $result = GetOptions( \%options,
        'client_insurance|ci=i',
        'mental_health_insurance|mhi',
        'dump',
    );

    $self->options( \%options );
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dispatch {
    my $self = shift;

    for my $key( keys %{ $self->options }) {
        next if grep /^$key$/ => qw/ dump /;
        die 'No method for: '. $key
            unless $self->can( $key );
        $self->$key;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $self = Audit->new;
$self->dispatch;

# $self->list_by_rank;
# $self->distribution( 2 );
# $self->distribution( 3 );
# $self->trifecta;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client_insurance { #{{{
    my $self = shift;
    my( $client_id );

    $client_id ||= $self->options->{ client_insurance };
    my $query = qq/
        -- select name, rank, rolodex_mental_health_insurance.rec_id AS mhid, rolodex.rec_id AS rid
        select rolodex.*, rolodex_mental_health_insurance.*, client_insurance.*,
        rolodex_mental_health_insurance.rec_id AS mhid, rolodex.rec_id AS rid
        from rolodex, rolodex_mental_health_insurance, client_insurance
        where rolodex.rec_id = rolodex_mental_health_insurance.rolodex_id
        and rolodex_mental_health_insurance.rec_id  = client_insurance.rolodex_insurance_id
        and client_insurance.active = 1
        and client_insurance.carrier_type = 'mental health'
        and client_insurance.client_id = $client_id
        order by rank
    /;
    my $results = $self->db->do_sql( $query );
    return print Dumper $results
        if $self->options->{ dump };

    $~ = 'CI_REPORT';
    format CI_REPORT = 
    @<<<<<  @<<   @<<<<  @<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $_->{ client_id }, $_->{ rank }, $_->{ mhid }, $_->{ rid }, $_->{ name }
.
    print <<'';
    Client  Rank  MHid   Rid    Name
    ----------------------------------------------------

    for( @$results ) {
        write;
    }
}
#}}}
sub mental_health_insurance { #{{{
    my $self = shift;

    print "    Active mental health insurers\n";

    my $query = qq/
        -- select distinct name, rolodex_mental_health_insurance.rec_id AS mhid, rolodex.rec_id AS rid
        select distinct rolodex.rec_id, rolodex.*, rolodex_mental_health_insurance.*,
        rolodex_mental_health_insurance.rec_id AS mhid, rolodex.rec_id AS rid
        from rolodex, rolodex_mental_health_insurance
        where rolodex.rec_id = rolodex_mental_health_insurance.rolodex_id
        order by name
    /;
    my $results = $self->db->do_sql( $query );
    return print Dumper $results
        if $self->options->{ dump };

    $~ = 'MHI_REPORT';
    format MHI_REPORT = 
    @<<<<  @<<<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    $_->{ mhid }, $_->{ rid }, $_->{ name }
.
    print <<'';
    MHid   Rid    Name
    ----------------------------------------------------

    for( @$results ) {
        write;
    }
}
#}}}

# methods below aren't available yet on the command line, but are still useful
sub list_by_rank { #{{{
    my $self = shift;

    $self->primary_mental_health_insurers;
    $self->primary_mental_health_insurers( 1 );
    $self->primary_mental_health_insurers( 2 );
    $self->primary_mental_health_insurers( 3 );
}
#}}}
sub primary_mental_health_insurers { #{{{
    my $self = shift;
    my( $rank, $return ) = @_;

    my( $name, $id, $clients, $iid );
    format PAYER_COUNT = 
@>>>>>>: @<<<<<<<<<<<<<<<<<<<< # @>>> / @<<<<<<<
$clients, $name, $id, $iid
.
    $~ = 'PAYER_COUNT';

    my $query = get_query( $rank );
    my $results = $self->db->do_sql( $query );
    return $results if $return;

    print( ( $rank ? $rank : 'All' ), " Mental Health Insurers", "\n", '~'x50, "\n" );
    for( @$results ) {
        ( $name, $id, $clients, $iid )
#             = ( $$_{ name }, $$_{ rolodex_id }, $$_{ clients }, $$_{ rolodex_insurance_id } );
            = ( $$_{ name }, $$_{ rolodex_id }, $$_{ clients }, $$_{ rolodex_insurance_id } );
        write;
    }
    print "\n";
}
#}}}
sub distribution { #{{{
    my $self = shift;
    my( $rank ) = @_;

    my @primary = @{ $self->primary_mental_health_insurers( 1, 'return' )};

    for my $primary( @primary ) {
        my $query = qq/
            SELECT COUNT( client_insurance.client_id ) AS clients, rolodex.name, rolodex.rec_id AS rolodex_id
            FROM client_insurance, rolodex_mental_health_insurance, rolodex
            WHERE client_insurance.active = 1
            AND client_insurance.rolodex_insurance_id = rolodex_mental_health_insurance.rec_id
            AND rolodex_mental_health_insurance.rolodex_id = rolodex.rec_id
            AND carrier_type = 'mental health'
            AND rank = '$rank'
            AND client_insurance.client_id IN (
                SELECT client_id
                FROM client_insurance
                WHERE carrier_type = 'mental health'
                AND rolodex_insurance_id = $$primary{ rolodex_insurance_id } AND rank = 1
                ORDER BY client_id
            )
            GROUP BY rolodex.name, rolodex.rec_id
            ORDER BY clients DESC
        /;
        my $results = $self->db->do_sql( $query );
        print "For $$primary{ name } ($$primary{ rolodex_id }):\n";
        for( @$results ) {
            print "    $$_{ clients } have $$_{ name }\n";
        }
        print "\n\n";
    }
}
#}}}
sub get_query { #{{{
    my( $rank, $where ) = @_;

    my $where_rank = $rank
        ? "AND rank = '$rank'"
        : '';
    $where ||= '';
    my $query = qq/
        SELECT
            DISTINCT client_insurance.rolodex_insurance_id,
            rolodex.rec_id AS rolodex_id,
            rolodex.name,
            COUNT( client_insurance.client_id ) AS clients
        FROM client_insurance, rolodex_mental_health_insurance, rolodex
        WHERE client_insurance.active = 1
        AND client_insurance.rolodex_insurance_id = rolodex_mental_health_insurance.rec_id
        AND rolodex_mental_health_insurance.rolodex_id = rolodex.rec_id
        AND carrier_type = 'mental health'
        AND rolodex.rec_id NOT IN ( $EXCLUDE )
        $where_rank
        $where
        GROUP BY client_insurance.rolodex_insurance_id, rolodex.rec_id, rolodex.name
        ORDER BY clients DESC
    /;
}
#}}}
sub trifecta { #{{{
    my $self = shift;
    my( $rank ) = @_;

    my @primary = @{ $self->primary_mental_health_insurers( 1, 'return' )};

    for my $primary( @primary ) {
        my $query = qq/
            SELECT
                DISTINCT client_insurance.rolodex_insurance_id,
                client_insurance.rec_id,
                rolodex.rec_id AS rolodex_id,
                rolodex.name,
                client_insurance.client_id,
                rank,
                COUNT( client_insurance.client_id ) AS clients
            FROM client_insurance, rolodex_mental_health_insurance, rolodex
            WHERE client_insurance.active = 1
            AND client_insurance.rolodex_insurance_id = rolodex_mental_health_insurance.rec_id
            AND rolodex_mental_health_insurance.rolodex_id = rolodex.rec_id
            AND carrier_type = 'mental health'
            AND client_insurance.rank > 1

                AND client_insurance.client_id IN (
                    SELECT client_id FROM client_insurance
                    WHERE rank = 1 AND rolodex_insurance_id = $$primary{ rolodex_insurance_id }
                    AND active = 1
                    AND client_id IN( SELECT client_id
                        FROM client_insurance
                        WHERE carrier_type = 'mental health'
                        AND rank = 2 AND active = 1
                    )
                )

            GROUP BY client_insurance.rec_id, client_insurance.rolodex_insurance_id, rolodex.rec_id, rolodex.name, client_insurance.client_id, rank
            ORDER BY client_insurance.rank, client_insurance.client_id DESC
        /;
        my $results = $self->db->do_sql( $query );

    die Dumper $results->[ 0 ] if $primary->{ rolodex_insurance_id } == 15;

        print "For $$primary{ name } ($$primary{ rolodex_id }):\n";
        my $client_id = $results->[ 0 ]{ client_id };
        print "Client: $$_{ client_id }\n";
        for( @$results ) {
            unless( $client_id == $_->{ client_id }) {
                print "Client: $$_{ client_id }\n"
            }
            print "     $$_{ rank }: $$_{ name }\n";

            $client_id = $_->{ client_id };
        }
        print "\n\n";
    }
}
#}}}
