package eleMentalClinic::Contact::HasPhone;

use Moose::Role;

requires qw(primary_key id);


=head1 NAME

eleMentalClinic::Contact::HasPhone - access a record's phone numbers

=head1 SYNOPSIS

    package Foo::Bar;
    use eleMentalClinic::Util;
    with_moose_role 'eleMentalClinic::Contact::HasAddress';

    # Or use it like a regular Moose::Role if you're a Moose class

    sub primary_key { ... }
    sub id { ... }

=head1 DESCRIPTION

This role provides convenience methods to look up the phone contacts
associated with a record.

Phone numbers are returned as eleMentalClinic::Contact::Phone objects.

=head1 Requires

You must implement the following methods:

=head3 primary_key

=head3 id

Returns the primary key and id for the object used to look for it in the contacts table.

=head1 METHODS

=head3 phone

   my $phone = $record->phone;

Returns the primary phone number associated with the $record, if any.

=cut

sub phone {
    my $self = shift;

    return undef unless $self->primary_key and $self->id;

    require eleMentalClinic::Util;
    require eleMentalClinic::Contact::Phone;

    return eleMentalClinic::Util->filter_contact_primary(
        eleMentalClinic::Contact::Phone->get_by_(
            $self->primary_key, $self->id
        )
    );
}


=head3 phones

    my $active_phones = $record->phones;
    my $all_phones    = $record->phones({ inactive => 1 });

Returns the active phone numbers associated with the object.

If inactive is true, it returns B<all> phones, active and inactive.

Will return an empty array ref if the record has no phone numbers.

=cut

sub phones {
    my $self = shift;
    my ($args) = @_;

    return [] unless $self->primary_key and $self->id;

    require eleMentalClinic::Contact::Phone;
    my $phones =
      eleMentalClinic::Contact::Phone->get_by_( $self->primary_key, $self->id, 'primary_entry', 'DESC, rec_id ASC' );

    return $phones if ( $args->{inactive} );

    require eleMentalClinic::Util;
    return eleMentalClinic::Util->filter_contact_active($phones);
}


=head3 phone_f

    my $phone = $record->phone_f;
    my $normalized_phone = $record->phone_f($phone);

Gets/sets the primary phone number.

The phone number is normalized and returned as per phone_format().

=cut

sub phone_f {
    my $self = shift;
    my ($phone_f) = @_;

    return $self->phone_format( 'phone', $phone_f );
}

=begin deprecated

=head3 phone2_f

    my $phone = $record->phone_f;
    my $normalized_phone = $record->phone_f($phone);

Like L</phone_f> but gets/sets the second phone number L</phone_2>.

=end deprecated

=cut

sub phone2_f {
    my $self = shift;
    my ($phone_f) = @_;

    require Carp;
    Carp::confess("deprecated - use eMC::Contact::Phone instead");

    return $self->phone_format( 'phone_2', $phone_f );
}



=head3 phone_format

    my $phone = $record->phone_format($method);
    my $normalized_phone = $record->phone_format($method, $phone);

Gets/sets C<< $record->$method->phone_number >> normalizing the phone
number before getting or setting.

When setting, all non-numbers will be stripped.

When getting, it will return ###-###-####.

=cut

sub phone_format {
    my $self      = shift;
    my $method    = shift;
    my ($phone_f) = @_;

    my $phone;

    die "You must pass the method name as the first parameter"
      unless $method;

    if ( defined $phone_f ) {
        $phone = $phone_f;
        $phone_f =~ s/\D//g;
        $self->$method->phone_number($phone_f);
        return $phone;
    }
    else {
        return unless defined $self->$method;
        return if ( $self->$method->phone_number eq '' );
        $phone = $self->$method->phone_number;

        # XXX what happens to 15551234567?
        $phone =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/;
        return $phone;
    }
}

1;
