package eleMentalClinic::Contact::HasAddress;

use Moose::Role;

requires qw(primary_key id);


=head1 NAME

eleMentalClinic::Contact::HasAddress - access a record's addresses

=head1 SYNOPSIS

    package Foo::Bar;
    use eleMentalClinic::Util;
    use_moose_role 'eleMentalClinic::Contact::HasAddress';

    sub primary_key { ... }
    sub id { ... }

=head1 DESCRIPTION

This role provides convenience methods to look up the address contacts
associated with a record.

Addresses are returned as eleMentalClinic::Contact::Address objects.

=head1 Requires

You must implement the following methods:

=head3 primary_key

=head3 id

Returns the primary key and id for the object used to look for it in the contacts table.

=head1 METHODS

=head3 address

   my $address = $record->address;

Returns the primary address associated with the $record, if any.

=cut

sub address {
    my $self = shift;

    return undef unless $self->primary_key and $self->id;

    require eleMentalClinic::Util;
    require eleMentalClinic::Contact::Address;

    return eleMentalClinic::Util->filter_contact_primary(
        eleMentalClinic::Contact::Address->get_by_(
            $self->primary_key, $self->id
        )
    );
}


=head3 addresses

    my $active_addresses = $record->addresses;
    my $all_addresses    = $record->addresses({ inactive => 1 });

Returns the active addresses associated with the object.

If inactive is true, it returns B<all> addresses, active and inactive.

Will return an empty array ref if the record has no addresses.

=cut

sub addresses {
    my $self = shift;
    my ($args) = @_;

    return [] unless $self->primary_key and $self->id;

    require eleMentalClinic::Contact::Address;
    my $addresses =
      eleMentalClinic::Contact::Address->get_by_( $self->primary_key, $self->id, 'primary_entry', 'DESC, rec_id ASC' );

    return $addresses if ( $args->{inactive} );

    require eleMentalClinic::Util;
    return eleMentalClinic::Util->filter_contact_active($addresses);
}


=head1 SEE ALSO

L<eleMentalClinic::Contact::Address>
L<eleMentalClinic::Contact::HasContacts>

=cut

1;
