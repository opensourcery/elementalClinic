# vim: ts=4 sts=4 sw=4
package eleMentalClinic::CGI::Rolodex;
use strict;
use warnings;
use Carp ();

use eleMentalClinic::Contact::Phone;

=head1 NAME

eleMentalClinic::CGI::Rolodex

=head1 DESCRIPTION

Base class for controllers that deal with rolodex entries (that is, objects
inheriting from L<eleMentalClinic::Rolodex::Base>).

=head1 METHODS

=cut

use base 'eleMentalClinic::CGI';

# XXX it seems like some of this should maybe be in the rolodex model
# (Rolodex::Base), but right now I'm putting it into the controller layer
# because it strikes me as an adapter between the input and the model.  in the
# future, perhaps the rolodex should be able to deal with this stuff on its
# own.

sub _rolodex_id {
    my $self = shift;
    my ( $rolodex ) = @_;

    # this is a bit of a hack; we're assuming no other table will be introduced
    # that has phone numbers related to it and uses a primary key of 'rec_id'
    my $pkey   = $rolodex->primary_key;
    my $id_key = $pkey eq 'rec_id' ? 'rolodex_id' : $pkey;

    return (
        $id_key => $rolodex->$pkey,
    ),
}

my %contact_class = (
    addresses => 'eleMentalClinic::Contact::Address',
    phones    => 'eleMentalClinic::Contact::Phone',
);
sub _save_contact {
    my $self = shift;
    my ( $rolodex, $contact_method, $data, $index ) = @_;

    # don't let form data override primary keys
    %$data = ( %$data, $self->_rolodex_id( $rolodex ) );

    my $contact = $rolodex->$contact_method->[ $index ||= 0 ];

    $contact ||= $contact_class{$contact_method}->new({
        active => 1,
        primary_entry => ( $index == 0 ) ? 1 : 0,
    });

    for my $key (@{ $contact->fields }) {
        $contact->$key( $data->{$key} )
            if exists $data->{$key} and $key ne "rec_id";
    }

    return $contact->save;
}


sub _delete_contact {
    my $self = shift;
    my ( $rolodex, $contact_method, $index ) = @_;

    my $contact = $rolodex->$contact_method->[ $index ||= 0 ];
    return if !$contact;

    return $contact->delete;
}


=head2 save_phone

    my $phone = $controller->save_phone(
        $rolodex,
        $phone_number,
        $index,
    );

Update or create the phone number for the given rolodex.  C<$index> is
optional; if not given, it will default to 0 (the primary phone number).

Automatically determines whether the rolodex is a client or not.

=cut

sub save_phone {
    my $self = shift;
    my ( $rolodex, $phone_number, $index ) = @_;

    # Don't delete the primary phone number.
    return if !$phone_number and $index == 0;

    if( $phone_number =~ /\S/ ) {
        return $self->_save_contact(
            $rolodex,
            'phones',
            { phone_number => $phone_number },
            $index,
        );
    }
    else {
        return $self->_delete_contact(
            $rolodex,
            'phones',
            $index,
        );
    }


}

=head2 save_phones

    my @phones = $controller->save_phones(
        $rolodex,
        \%vars,
        \@keys,
    );

For each key in C<@keys>, this calls L</save_phone>.

This is just a convenience which takes care of passing C<$index> to
L</save_phone> for you.

Returns a list of phone objects (or C<undef>, if a key was not in C<%vars>).

=cut

sub save_phones {
    my $self = shift;
    my ( $rolodex, $vars, $keys ) = @_;

    Carp::croak 'usage: save_phones( $rolodex, $vars, $keys )' unless @_ == 3;

    my @phones;
    $self->db->transaction_do(sub {
        my $index = 0;
        for ( @$keys ) {
            push @phones, $self->save_phone(
                $rolodex,
                $vars->{$_},
                $index++,
            );
        }
    });
    return @phones;
}

=head2 save_address

    my $address = $controller->save_address(
        $rolodex,
        \%address_data,
        $index,
    );

Update or create the address for the given rolodex.  C<$index> is optional; if
not given, it will default to 0 (the primary address).

Automatically determines whether the rolodex is a client or not.

=cut

sub save_address {
    my $self = shift;
    my ( $rolodex, $data, $index ) = @_;

    return $self->_save_contact(
        $rolodex,
        'addresses',
        $data,
        $index,
    );
}

1;
