package eleMentalClinic::Contact::HasContacts;

use Moose::Role;
with qw(eleMentalClinic::Contact::HasAddress eleMentalClinic::Contact::HasPhone);

no Moose::Role;
1;

=head1 NAME

eleMentalClinic::Contact::HasContacts - Add contact methods to a record

=head1 SYNOPSIS

    use eleMentalClinic::Util;
    with_moose_role("eleMentalClinic::Contact::HasContacts");

    # or if you're a Moose class, use it like a normal Moose::Role

=head1 DESCRIPTION

Provides several contact-related roles in one role for convenience:
L<eleMentalClinic::Contact::HasAddress> and
L<eleMentalClinic::Contact::HasPhone>.

Others may be added in the future.

=cut
