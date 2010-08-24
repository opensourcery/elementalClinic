# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Rolodex;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::Rolodex

=head1 SYNOPSIS

Parent object for rolodex items: entities which are not employed or receiving services at the clinic, but do have a relationship with one or more clients.

=head1 METHODS

=cut

use base qw/ eleMentalClinic::DB::Object /; 

use eleMentalClinic::Util;
with_moose_role("eleMentalClinic::Contact::HasContacts");

use eleMentalClinic::ValidData;
use eleMentalClinic::Client;
use eleMentalClinic::Schedule;
use eleMentalClinic::Lookup::ChargeCodes;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub table { 'rolodex' }
    sub fields {
        [ qw/
            rec_id dept_id generic name fname lname
            credentials 
            comment_text client_id
            claims_processor_id edi_id edi_name
            edi_indicator_code
        /]
    }
    sub primary_key { 'rec_id' }
    # {{{ hand-rolled _in methods
    sub in_treaters {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_treaters",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_release {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_release",
            "rolodex_id = ". $self->rec_id,
       );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_referral {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_referral",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_prescribers {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_prescribers",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_mental_health_insurance {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_mental_health_insurance",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_medical_insurance {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_medical_insurance",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_employment {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_employment",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_dental_insurance {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_dental_insurance",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    sub in_contacts {
        my $self = shift;
        return unless $self->rec_id;

        my $hashref = $self->db->select_one(
            ['rec_id'],
            "rolodex_contacts",
            "rolodex_id = ". $self->rec_id,
        );
        return $hashref->{ rec_id } if $hashref->{ rec_id };
        return 0;
    }
    # }}}

}

# overridding init so we can add the role as an attribute
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my( $args ) = @_;
    $self->SUPER::init($args);

#    my $tables;
#    push @$tables, $_->{name} for @{eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_rolodex_roles')};
#
#    _in( ref $self, $_ ) for @$tables;
    eleMentalClinic::Base::attribute(ref $self, 'role');
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _in {
    my ( $pkg, $table ) = @_;

    no strict 'refs';
    return if "${ pkg }"->can( "in_$table" );
    *{ "${ pkg }::in_$table" } =
        sub {
            my $self = shift;
            return unless $self->rec_id;

            my $hashref = $self->db->select_one(
                ['rec_id'],
                "rolodex_$table",
                "rolodex_id = ". $self->rec_id,
            );
            return $hashref->{ rec_id } if $hashref->{ rec_id };
            return 0;
        };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub in {
    my $self = shift;
    return unless my $role = shift;
    my $method = "in_$role";
    return $self->$method;
}

# overridding save so we can make generic default to 0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my $self = shift;
    
    $self->generic(0) unless $self->generic;
   
    my $name = $self->name; 
    $name =~ s/(\w+\S*\w*)/\u\L$1/g if $name; 
    $self->name( $name );
    
    $name = $self->fname;
    $name =~ s/(\w+\S*\w*)/\u\L$1/g if $name;
    $self->fname( $name );

    $name = $self->lname;
    $name =~ s/(\w+\S*\w*)/\u\L$1/g if $name;
    $self->lname( $name );

    foreach my $phone (@{$self->phones}) {
        $phone->save;
    }

    foreach my $address (@{$self->addresses}) {
        $address->save;
    }

    # FIXME how do we enforce that a generic can't be changed?
    #return if( $self->generic eq 1 and $self->id );
    $self->SUPER::save(@_);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_one {
    my $self = shift;
    my( $rec_id ) = @_;
    return unless $rec_id;
    my $class = ref $self;
    
    my $where = "rec_id = $rec_id";
    # TODO test the return unless here
    return unless my $hashref = $self->db->select_one( $self->fields, $self->table, $where);
    $hashref = $class->new($hashref);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns al rolodex entries as an arrayref of hashrefs
sub list_all {
    my $self = shift;

    my $order_by = "ORDER BY lower( lname ), lower( fname ), lower ( name )";
    $self->db->select_many( $self->fields, $self->table, '', $order_by );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $self = shift;
    my $class = ref $self;

    return unless my $results = $self->list_all;
    my @results;
    push @results => $class->new( $_ ) for @$results;
    
    my @sorted = sort { lc($a->eman) cmp lc($b->eman) } @results;
    return \@sorted;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns rolodex entries of type $role as an arrayref of hashrefs
sub list_byrole {
    my $self = shift;
    my( $role, $client_id ) = @_;
    return unless $self->valid_role($role);
    
    my $tables = $self->table . ", rolodex_$role";
    my $where = "WHERE rolodex.rec_id = rolodex_$role.rolodex_id";
    $where .= " AND ( rolodex.client_id IS NULL or rolodex.client_id = $client_id )" if $client_id;
    my $order_by = "ORDER BY lower( lname ), lower( fname ), lower( name )";
    $self->db->select_many( ['rolodex.*'], $tables, $where, $order_by );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byrole {
    my $self = shift;
    my $class = ref $self;
    
    return unless my $results = $self->list_byrole( @_ );
    my @results;
    push @results => $class->new( $_ ) for @$results;
    
    my @sorted = sort { lc($a->eman) cmp lc($b->eman) } @results;
    return \@sorted;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns rolodex entries of type 'mental_health_insurance'
# who have a defined claims_processor,
# as an arrayref of hashrefs
sub list_edi_rolodexes {
    my $class = shift;
    
    my $tables = $class->table . ", rolodex_mental_health_insurance";
    my $where = "WHERE rolodex.rec_id = rolodex_mental_health_insurance.rolodex_id";
    $where .= " AND rolodex.claims_processor_id IS NOT NULL";
    my $order_by = "ORDER BY lower( name )";
    $class->db->select_many( ['rolodex.*'], $tables, $where, $order_by );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_edi_rolodexes {
    my $class = shift;

    return unless my $results = $class->list_edi_rolodexes( @_ );
    return [ map { $class->new( $_ ) } @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 last_received_edi()

Object method. Wrapper for BillingPayment->last_received_for_rolodex.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub last_received_edi {
    my $self = shift;

    return eleMentalClinic::Financial::BillingPayment->last_received_for_rolodex( $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# TODO cache this so this query only gets run once
sub role_names {
    my @role_names;

    return unless my $roles = eleMentalClinic::ValidData->new({ dept_id => 1001 })->list( '_rolodex_roles');
    push @role_names => $_->{ name }
        for @$roles;
    return \@role_names;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub roles {
    my $self = shift;
    my( $role ) = @_;

    unless( $role ) {
        my @roles;
        for ( sort keys %{ $eleMentalClinic::Client::lookups } ) {
            push @roles => $eleMentalClinic::Client::lookups->{$_};
        }
        return \@roles;
    }
    return $eleMentalClinic::Client::lookups->{ $role };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub add_role {
    my $self = shift;
    my( @roles ) = @_;
    return unless @roles and $self->rec_id;

    for my $role (@roles) {
        die "$role is not a valid role" unless $self->valid_role($role);
        my $in = "in_$role";
        unless ($self->$in) {
            $self->db->insert_one(
                "rolodex_$role", 
                ['rolodex_id'],
                [$self->rec_id] );
        }
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub remove_role {
    my $self = shift;
    my( @roles ) = @_;
    return unless @roles and $self->rec_id;

    # loop through roles, check if there are records in
    #  the corresponding table (?) and 
    #  if there aren't, delete it
    #  if there are, don't and set some flag to false
    #
    #  ? = the table is 'client_' . everything after
    #  the last underscore in $role
    my $success = 1;
    
    for my $role (@roles) {
        die "$role is not a valid role" unless $self->valid_role($role);
        next if $role eq 'release'; #TODO get rid of release

        my $lookup = $eleMentalClinic::Client::lookups->{$role};
        
        my $client_table = $lookup->{client_table};
        my $role_id = $lookup->{role_id};

        my $role_table = $lookup->{role_table};
        
        my $id = $self->rec_id;

        my $where = qq/
            $client_table.$role_id = $role_table.rec_id
                AND $role_table.rolodex_id = $id
        /;

        if( $role =~ m/_insurance/ ) {
            my $carrier_type = $role;
            $carrier_type =~ s/_insurance//;
            $carrier_type =~ s/_/ /;
            $where .= " AND carrier_type = '$carrier_type'";
        }
        
        my $count = $self->db->select_one(
            ["count($client_table.*)"],
            "$client_table, $role_table",
            $where
        )->{count};
        unless ($count) {
            my $in = "in_$role";
            if ($self->$in) {
                $self->db->delete_one(
                    $role_table, 
                    'rolodex_id = ' . $self->rec_id );
            }
        }
        else {
            $success = 0;
        }
    }
    return $success;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub valid_role {
    my $self = shift;
    my( $role ) = @_;
    return unless $role;
    my $list = $self->role_names;
    for (@$list) {
        return 1 if $role eq $_;
    }
    return 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns a hashref where keys are role names and values are:
# 1 if rolodex has that role for client, 0 otherwise
sub client_roles {
    my $self = shift;
    return unless my $client_id = shift;
    return unless $self->id;

    my $rolodex_id = $self->id;
    my %roles;
    for( @{ $self->role_names }) {
        next if $_ eq 'prescribers' or $_ eq 'release';
        $roles{ $_ } = 0;
        my $role = $self->roles( $_ );
        my $client_table = $role->{ client_table };
        my $role_table = $role->{ role_table };
        my $role_id = $role->{ role_id };

        my $carrier_type = $role->{ carrier_type };
        $carrier_type = $carrier_type
            ? " AND $client_table.carrier_type = '$carrier_type'"
            : '';

        $roles{ $_ } = 1 if $self->db->select_one(
            [ "$role_table.rec_id" ],
            "$client_table, $role_table",
            "$client_table.client_id = $client_id"
            . " AND $role_table.rolodex_id = $rolodex_id"
            . " AND $client_table.$role_id = $role_table.rec_id"
            . $carrier_type,
        );
    }
    return \%roles;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub name_f {
    my $self = shift;

    return $self->name if $self->name;
    return unless $self->fname or $self->lname;

    my $name;
    if( $self->fname and $self->lname ) {
        $name = $self->fname .' '. $self->lname;
    }
    else {
        $name = $self->fname if $self->fname;
        $name = $self->lname if $self->lname;
    }
    $name .= ', '. $self->credentials if $self->credentials;
    $name;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns "Last, First (Credentials)"
sub eman {
    my $self = shift;

    my $creds = '('. $self->credentials .')'
        if $self->credentials;
    $self->SUPER::eman(
        ( $self->lname and $self->fname )
            ? ( $self->fname, $self->lname )
            : ( $self->name, undef ),
        $creds
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns "Last, First (Company)"
sub eman_company {
    my $self = shift;

    if( $self->lname and $self->fname ) {
        my $company = $self->name
            ? '('. $self->name .')'
            : '';
        return $self->SUPER::eman( $self->fname, $self->lname, $company );
    }
    else {
        return $self->SUPER::eman( $self->name );
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub make_private {
    my $self = shift;
    die "rolodex object does not have a rec_id" 
        unless my $rolodex_id = $self->rec_id;
    die "make_private takes a client_id" 
        unless my( $client_id ) = @_;

    my $success;
    for( @{$self->roles} ){
        my $client_table = $_->{ client_table };
        my $role_table = $_->{ role_table };
        my $role_field = $_->{ role_id };
        $role_field = 'rolodex_id' if $_->{ name } eq 'release';

        # search in $client_table to see if a client that isn't $client_id has
        # a relationship with rolodex $rolodex_id, whose relationship id you'll
        # have to get out of $role_table, and will be stored in $role_field
        return unless $self->db->select_one(
            ['count(*)'],
            "$client_table ct, $role_table rt",
            qq/ ct.client_id != $client_id
                AND rt.rolodex_id = $rolodex_id
                AND rt.rec_id = ct.$role_field
            /
        )->{ count } eq 0;
    }

    # if we got no conflicts, save the client_id to the object
    $self->client_id( $client_id );
    $self->save;

    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_private {
    my $self = shift;
    return unless my( $client_id ) = @_;
    return unless $self->client_id;
    return unless $client_id != $self->client_id;
    1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub dup_check {
    my $self = shift;

    my $name = $self->name;
    my $fname = $self->fname;
    my $lname = $self->lname;
    my $id = $self->id;
    my $credentials = $self->credentials;
    my $class = ref $self;

    my $result = {
        name => undef,
        fname_lname_cred => undef,
    };

    return $result unless $name or ($fname and $lname);

    if( $name ) {
        my @bind = $name;
        my $where = "lower(name) = lower(?)";
        if ($id and $id > 0) {
            $where .= " AND rec_id != ?";
            push @bind, $id;
        }

        my $data_holder = $self->db->select_one(
            ['rec_id'],
            'rolodex',
            [ $where, @bind ]
        );

        $result->{ name } = $class->new({
            rec_id => $data_holder->{ rec_id },
        })->retrieve if $data_holder->{ rec_id };
    }

    if( $fname and $lname ) {
        
        my $where = "WHERE lower(fname) = lower(?) AND lower(lname) = lower(?) ";
        my @bind = ($fname, $lname);
        if( $credentials ) {
            $where .= "AND lower(credentials) = lower(?)";
            push @bind, $credentials;
        } else {
            $where .= "AND ( credentials is NULL or credentials = '' )";
        } 
        if ( $id and $id > 0 ){
            $where .= " AND rec_id != ?";
            push @bind, $id;
        }

        my $data_holder = $self->db->select_many(
            ['rec_id'],
            'rolodex',
            [ $where, @bind ],
        );

        if( $data_holder and scalar @$data_holder > 0 ) {
            for( @$data_holder ) {
                push @{ $result->{ fname_lname_cred } }, 
                $class->new({
                    rec_id => $_->{ rec_id },
                })->retrieve unless $result->{ name } and $_->{ rec_id } eq $result->{ name }->{ rec_id };
            }
        }
    }

    return $result;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub role {
    my $self = shift;
    my( $value ) = @_;
    my $attribute = 'role';
    if( defined $value ) {
        $self->{ $attribute } = ( $value eq '*NULL' )
            ? undef
            : $value;
        return $self;
    }
    else {
        return undef unless defined $self->{ $attribute };
        return undef if( $self->{ $attribute } eq '' );
        return $self->{ $attribute };
    }
};

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_by_role_id {
    my $self = shift;
    my( $role, $role_id ) = @_;
    my $class = ref $self;
    
    return unless $self->valid_role( $role ) and $role_id;

    return unless my $result = $self->db->select_one( 
        [ 'rolodex_id' ], 
        "rolodex_$role", 
        "rec_id = $role_id"
    );
    
    return $class->new({ rec_id => $result->{ rolodex_id } })->retrieve;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub find_similar {
    my $self = shift;
   
    my $rec_id = $self->rec_id || 0;
    
    my $match_roles = ' AND ( 1 = 0 ';
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_treaters) " if( $self->in_treaters );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_referral) " if( $self->in_referral );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_mental_health_insurance) " if( $self->in_mental_health_insurance );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_medical_insurance) " if( $self->in_medical_insurance );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_employment) " if( $self->in_employment );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_dental_insurance) " if( $self->in_dental_insurance );
    $match_roles .= " OR rec_id in (SELECT rolodex_id from rolodex_contacts) " if( $self->in_contacts );
    $match_roles .= ' ) '; 

    # TODO: decide what to do here
    # don't concern ourselves with roles for now
    $match_roles = '';
   
    my $where = qq/ WHERE ( LOWER(name) IN ( SELECT LOWER(name) FROM rolodex WHERE rec_id = $rec_id )
                         OR ( LOWER(fname) IN ( SELECT LOWER(fname) FROM rolodex WHERE rec_id = $rec_id ) 
                            AND LOWER(lname) IN ( SELECT LOWER(lname) FROM rolodex WHERE rec_id = $rec_id ) ) )
                    AND rec_id != $rec_id /;
    
    my $matching = $self->db->select_many(
        ['rec_id'],
        'rolodex',
        $where . $match_roles
    );
    
    my $to_merge;
    foreach( @$matching ) {
        push @$to_merge => values %$_;
    }
    
    # remove duplicates and sort
    my %union;
    foreach( @$to_merge ){
        $union{ $_ } = 1;
    }
    @$to_merge = sort keys %union;
    
    return $to_merge;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub merge {
    my $self = shift;
    my $old_ids = shift;

    my $old_id_list = join( ', ' => @$old_ids );
    my $new_id = $self->rec_id;

    my %tables =  ( rolodex_treaters => { secondary_tables => ['personnel', 'client_medication', 'client_treaters'],
                                          secondary_table_field => 'rolodex_treaters_id',
                                        },
                    rolodex_contacts => { secondary_tables => ['client_contacts'],
                                          secondary_table_field => 'rolodex_contacts_id', 
                                        },
                    rolodex_employment => { secondary_tables => ['client_employment'],
                                            secondary_table_field => 'rolodex_employment_id', 
                                          },
                    rolodex_medical_insurance => { secondary_tables => ['client_insurance'],
                                                   secondary_table_field => 'rolodex_insurance_id', 
                                                 },
                    rolodex_mental_health_insurance => { secondary_tables => ['client_insurance'],
                                                         secondary_table_field => 'rolodex_insurance_id', 
                                                       },
                    rolodex_dental_insurance => { secondary_tables => ['client_insurance'],
                                                  secondary_table_field => 'rolodex_insurance_id', 
                                                },
                    rolodex_referral => { secondary_tables => ['client_referral'],
                                          secondary_table_field => 'rolodex_referral_id', 
                                        },
                    rolodex_release => undef,
                    client_release => undef,
                   );
                               
    eval { 
        $self->db->transaction_do(sub {
           
            #TODO - The temporary setting of duplicate rolodex_id's in the rolodex_ROLE table is preventing a UNIQUE constraint from being set on the rolodex_ROLE.rolodex_id field.  I believe the UNIQUE constraint makes sense, but it may not be that critical.  Applying the constraint would require that this method first remove duplicate rolodex_ROLE rows before moving on to rolodex itself.
     
            $self->db->do_sql( qq/ UPDATE $_ SET rolodex_id = $new_id where rolodex_id in ( $old_id_list ) /, 'return' ) for keys %tables;
            # Delete from similar_rolodex before rolodex, otherwise db will complain about foreign keys
            $self->db->do_sql( qq/ DELETE FROM similar_rolodex WHERE rolodex_id in ( $old_id_list, $new_id ) /, 'return' );
            $self->db->do_sql( qq/ DELETE FROM rolodex WHERE rec_id in ( $old_id_list ) /, 'return' );

            # Take all of the rolodex role tables that are now pointing to the same rolodex
            for my $role_table ( keys %tables ){

                # but don't merge records in this table!
                next if( $role_table eq 'client_release' );
                
                my $result = $self->db->select_many(
                    ['rec_id'],
                    $role_table,
                    "WHERE rolodex_id = $new_id",
                    'ORDER BY rec_id',
                );

                # select the first one as the one to keep
                my @entries;
                push @entries => values %$_ for @$result;
                my $new_entry_id = shift @entries;
                if( scalar @entries > 0 ){
                    my $old_entry_ids = join ', ' => @entries;
                    
                    # update each of the tables that point to the duplicate tables - 
                    # set them pointing to the chosen one.
                    for my $sec_table ( @{$tables{ $role_table }{ secondary_tables }} ){
                        $self->db->do_sql( qq/ UPDATE $sec_table
                                                SET $tables{ $role_table }{ secondary_table_field } = $new_entry_id
                                                WHERE $tables{ $role_table }{ secondary_table_field } IN ( $old_entry_ids ) /, 'return' );
                    }

                    # and delete all of the old role tables that were duplicates, and aren't needed anymore.
                    $self->db->do_sql( qq/ DELETE FROM $role_table WHERE rec_id IN ( $old_entry_ids ) /, 'return' );
                }
            }
        });
    };
    
    if( $@ ){
        warn "Merge Transaction FAILED because $@";
        return 0;
    }
    return 1;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub cache_similar {
    my $self = shift;
    my $matching;
    my $rolodex_id;
   
    $self->db->do_sql( qq/ DELETE FROM similar_rolodex /, 'return' );
    
    my $sth = $self->db->dbh->prepare( qq/ INSERT INTO similar_rolodex 
                                           (rolodex_id, matching_ids, modified) 
                                    VALUES ( ?, ?, CURRENT_TIMESTAMP ) / );

    for( @{ $self->get_all } ){
        $rolodex_id = $_->{ rec_id };
        my $list = $_->find_similar;
        if( scalar @$list > 0 ){
            $matching = join ', ' => @$list;
            $sth->execute( $rolodex_id, $matching );
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# get a list of the rolodex entries that have similar entries
# and their num matches, and with duplicates removed
# returns: hash with key = id, values = num_matches
sub similar_entries {
    my $self = shift;

    my $results = $self->db->select_many(
        ['rolodex_id', 'matching_ids'],
        'similar_rolodex',
        '',
        'ORDER BY rolodex_id',
    );

    my %entries;
    my %seen;
    for( @$results ){
        if( ! defined $seen{ $_->{ rolodex_id } } ){
            my @list = split(/, / => $_->{ matching_ids });
            $entries{ $_->{ rolodex_id } } = scalar @list;
            for my $id ( @list ){
                $seen{ $id } = 1;
            }
        }
    }

    return \%entries;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Fetch the matching ids for a requested id,
# returns: array of ids
sub matching_ids {
    my $self = shift;
    my $rolodex_id = shift;
 
    my $result = $self->db->dbh->selectrow_arrayref( qq/ SELECT matching_ids 
                                                 FROM similar_rolodex
                                                WHERE rolodex_id = ? /, undef, $rolodex_id );

    my @list = ();
    if( defined $result and scalar @$result > 0 ){
        @list = split(/, / => @$result[0]);
    } 
    
    return \@list;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub similar_modified {
    my $self = shift;

    my $results = $self->db->select_one(
        ['max(modified)'],
        'similar_rolodex',
        '1 = 1',
        '',
    );
   
    if( defined $results->{ max } ){
        my ($date) = ($results->{ max } =~ m/^(\d{4}-\d+-\d+ \d+:\d+)/);
        return $date;
    }
    else {
        return '';
    }
}    

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub schedule {
    my $self = shift;
    
    return eleMentalClinic::Schedule->new({ rolodex_id => $self->id });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub charge_code_associations {
    my $self = shift;
    my( $only_associated_codes ) = @_;

    die 'Must call on stored object'
        unless $self->id;
    return eleMentalClinic::Lookup::ChargeCodes->charge_codes_by_insurer( $self->id, $only_associated_codes );
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
