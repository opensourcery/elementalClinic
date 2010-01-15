# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

package eleMentalClinic::Base::DB;

use Carp;
use eleMentalClinic::DB;
use Sub::Exporter -setup => {
  exports => [qw(
    fields_qualified
    fields_qualified_arrayref
    retrieve
    get_byid
    get_all
    list_all_by_client
    get_all_by_client
    id
    save
    delete

    get_many_where
    get_one_where
    _get_where
    _inflate_row

    client
    rolodex
    personnel

    update
    role
    get_by_
    get_one_by_
    build_db_accessors
    accessors_retrieve_one
    build_one_to_one_accessors
    accessors_retrieve_many
    build_one_to_many_accessors
    table fields fields_required primary_key

    clone
  )],
};

=head2 fields_qualified([ $class ])

Class method.

Returns a list of the classes (or object's) fields, prepended with the table
name.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub fields_qualified_arrayref {
    my $proto = shift;
    die 'Must be called on an object or class which has a "fields" method.'
        unless $proto->can( 'fields' );
    return
        unless $proto->fields
        and @{ $proto->fields };
    my @fields;
    if ( @_ ) {
        my %known = map {( $_ => 1 )} @{ $proto->fields };
        my @unknown = grep { ! $known{$_} } @_;
        die "Can't qualify unknown fields for $proto: @unknown" if @unknown;
        @fields = @_;
    } else {
        @fields = @{ $proto->fields };
    }

    return [ map{ $proto->table .".$_" } @fields ];
}

sub fields_qualified {
    my $class = shift;
    my $fields = $class->fields_qualified_arrayref( @_ );
    return unless $fields;
    return join(', ', @$fields);
}

=head2 retrieve( [ $id ] )

Class or Object method.

Returns an object of the type that called it.  Complex for legacy reasons.

If passed C<$id> or called as an object method by an object with an existing
id, retrieves that object from the database and returns it.  Otherwise returns
an empty object.

If called as a class method, C<$id> is required.  Otherwise behaves the same
way.

Two major benefits compared with original method, and the reason for the refactor, are:

=over 4

=item Better syntax

    ClassName->retrieve( 1 );
    # as opposed to:
    ClassName->new({ rec_id => 1 })->retrieve;

=item Required fields

Because of the way C<retrieve()> used to be called, it was not possible to
require fields in an object's C<init()> method (because C<init()> is called by
C<new()>, and with the mostly blank C<new()> those required fields were never
present).

=back

Note that I used C<empty()> to construct the object rather than C<new()>.  This
is to prevent C<retrieve()> from dying unexpectedly with less than perfect
data, or when it would otherwise return undef.

This is the original code, preserved for posterity.  It's my strong belief that
the new method is functionally equivalent in all important respects in use by
the codebase.

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sub retrieve {
        my $self = shift;
        my $object;
        $object = $self->get_byid if $self->id;
        # taking this out for now, it would be a good 
        #  way to save db lookups later
        #  (it just gets in the way of tests now)
        #$self->{ retrieved } = 1 if defined $object;
        $object = $self->new($object) unless defined $object->{id};
        $self->init( $object );
    }
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sub get_byid {
        my $self = shift;
        $self->db->select_one( $self->fields, $self->table, $self->primary_key . ' = ' . $self->id );
    }

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub retrieve {
    my $proto = shift;
    my( $id ) = @_;

    my( $class, $self ) = ref $proto
        ? ( ref $proto, $proto )    # $proto is likely an object
        : ( $proto, undef );        # $proto is likely a class name
    confess 'ID is required if calling retrieve as a class method'
        if not defined $id and not $self;

    $id = $self->id
        unless defined $id;
    my $object = $class->empty( $class->get_byid( $id ));
    return $object unless $self;
    # XXX still too stupid to see why this extra init() is necessary
    return $proto->init( $object, { empty => 1 });
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_byid()

Class method.

This query needs to be overridden in L<eleMentalClinic::Client>, so we break it
out into a different routine.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_byid {
    my $class = shift;
    my( $id ) = @_;

    return unless $id;
    return $class->db->select_one(
        $class->fields,
        $class->table,
        [ $class->primary_key . ' = ?', $id ],
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all {
    my $proto = shift;

    my ($order_by) = @_;

    my $class = ref $proto || $proto;
    return unless $class->fields and $class->table;

    $order_by ||= $class->primary_key;

    my $objects;
    if( $class->can( 'list_all' )) {
        $objects = $class->list_all( @_ );
    }
    else {
        $objects = $class->db->select_many(
            $class->fields,
            $class->table,
            '',
            $order_by ? "ORDER BY " . $order_by : '',
        );
    }
    return unless $objects;
    return[ map{ $class->new( $_ )} @$objects ];
}

sub _get_where {
    my $class = shift;
    my ( $method, $where, $other, $from ) = @_;

    $from ||= [ $class->table ];

    for (qw(fields table)) {
        die "$class: can't get_*_where with no $_" unless $class->$_;
    }
    my $result = $class->db->$method(
        $class->fields_qualified_arrayref,
        join(' ', @$from),
        $where,
        $other,
    );
    return unless $result;

    return $result if !$class->primary_key && ref $result eq 'ARRAY';
    if ( ref $result eq 'ARRAY' ) {
        my %seen;
        my $pk = $class->primary_key;
        return [
            grep { ! $seen{ $_->$pk }++ }
            map { $class->_inflate_row( $_ ) } @$result
        ];
    }
    elsif ( ref $result eq 'HASH' ) {
        return $class->_inflate_row( $result );
    } 
    else {
        die "unhandled result: $result";
    }
}

sub _inflate_row {
    my $class = shift;
    my ( $row ) = @_;
    my $table = $class->table;
    return $class->new({
        map { 
            s/^\Q$table.\E//;
            $_ => $row->{$_}
        }
        keys %$row
    });
}

sub get_many_where {
    my $class = shift;
    $class->_get_where(select_many => @_);
}

sub get_one_where {
    my $class = shift;
    $class->_get_where(select_one => @_);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub list_all_by_client {
    my $class = shift;
    my( $client_id ) = @_;
    return unless $client_id;

    return $class->new->db->select_many(
        $class->fields,
        $class->table,
        [ 'WHERE client_id = ?', $client_id ],
        $class->primary_key ? 'ORDER BY '. $class->primary_key : '',
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_all_by_client {
    my $class = shift;
    return unless my $hashrefs = $class->list_all_by_client( @_ );

    my @results;
    push @results, $class->new( $_ ) for @$hashrefs;
    return \@results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub id {
    my ($self, $value) = @_;
    my $key = $self->primary_key;
    $key =~ s/\w+\.//;
    croak "'$key' not found at Base::id"
        unless $key and $self->can( $key );
    return $self->$key($value) if $value;
    return $self->$key;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub save {
    my ($self) = @_;
    if ($self->id) {
        $self->db->obj_update($self);
    }
    else {
        $self->db->obj_insert($self);
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub delete {
    my $self = shift;
    $self->db->delete_one( $self->table, $self->primary_key .'='. $self->id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 rolodex()

Object method.

Tries to find the L<eleMentalClinic::Rolodex> object associated with the
calling object.  Looks in the object's C<fields> method, and dies loudly if it
can't find one good candidate.

If the field is C<rolodex_id> it's easy, otherwise do some rigamarole joining
to the role tables.

Tested in t/001base.t with every object that can possibly call it.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub rolodex {
    my $self = shift;

    croak 'This object is not persistent (i.e. no "fields" method)'
        unless my $fields = $self->fields;

    my @candidates = grep /rolodex/ => @$fields;
    croak 'Cannot find a Rolodex relationship field.'
        unless @candidates;
    croak 'Too many fields found'
        if @candidates > 1;

    my $rolodex_field = shift @candidates;
    return unless my $rolodex_field_value = $self->$rolodex_field;

    # special case for simple 'rolodex_id' field
    return eleMentalClinic::Rolodex->retrieve( $rolodex_field_value  )
        if $rolodex_field eq 'rolodex_id';

    # continue with unsimple case
    ( my $rolodex_table = $rolodex_field ) =~ s/_id//;
    if( $rolodex_table eq 'rolodex_insurance' ) {
        return
            unless my $carrier = $self->carrier_type;
        $carrier =~ s/ /_/g;
        $rolodex_table = "rolodex_$carrier";
        $rolodex_table .= '_insurance';
    }
    return unless my $rolodex = $self->db->select_one(
        [ 'rolodex.*' ],
        "rolodex, $rolodex_table",
        qq/
            rolodex.rec_id = $rolodex_table.rolodex_id
            AND $rolodex_table.rec_id = $rolodex_field_value
        /
    );
    return eleMentalClinic::Rolodex->new( $rolodex );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update([ \%fields ])

Object method.

Updates the calling object with new values in C<%fields>.  First updates the object, then calls C<save()>.  Returns the return value of C<save()>, or undef.

=over 4

=item * Keys in C<%fields> not present in the object are ignored.

=item * Keys in C<%fields> with C<undef> values are set to C<NULL> in the database.  If the field is C<NOT NULL>, the database will throw an error.

=back

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub update {
    my $self = shift;

    return unless my( $args ) = @_;

    my $fields_updated = 0;
    while( my( $property, $value ) = each %$args ) {
        next unless $self->can( $property );
        $fields_updated++;
        $self->$property($value);
    }

    return unless $fields_updated;
    return $self->save;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub role {
    my $self = shift;

    return unless my $fields = $self->fields;
    return unless my @rolodex_field = grep m/rolodex/, @$fields;

    my $lookups = $eleMentalClinic::Client::lookups;
    my $class = ref $self;

    for( keys %$lookups ){
        my $info = $lookups->{ $_ };
        if( $class =~ m/Insurance/ 
            and $info->{ carrier_type }){
            return $_ if $info->{ carrier_type } eq $self->carrier_type;
        }
        else {
            return $_ if $info->{ class } eq $class;
        }
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_by_( $column, $value, [ $order_column, $direction ])

Class method.

Returns C<undef> or a list of all objects with C<$column> equal to C<$value>.
C<$value> must be a simple expression; it is quoted before being passed to the
query.

Objects are returned ordered by primary key, or C<$order_column>.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_by_ {
    my $class = shift;
    my( $column, $value, $order_column, $direction ) = @_;

    croak 'Column and value are required'
        unless $column and defined $value;
    croak 'Invalid column'
        if $column =~ /\W/ or( $order_column and $order_column =~ /\W/ );

    $direction ||= 'ASC';
    $order_column ||= $class->primary_key;
    my $results = $class->db->select_many(
        $class->fields,
        $class->table,
        [ "WHERE $column = ?", $value ],
        $order_column ? "ORDER BY $order_column $direction" : '',
    );
    return unless $results;
    return[ map{ $class->new( $_ )} @$results ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_one_by_( $column, $value, [ $order_column ])

Class method.

This method wraps C<get_by_>, and returns the first object returned by it.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_one_by_ {
    my $class = shift;

    my $objects = $class->get_by_( @_ );
    return unless $objects;
    return $objects->[ 0 ];
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head1 personnel()

Provides the associated Personnel object if current object
has a staff_id field.  Otherwise returns undef.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub personnel {
    my $self = shift;
    return unless $self->can( 'staff_id' ) and $self->staff_id;
    return eleMentalClinic::Personnel->retrieve( $self->staff_id );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub client {
    my $self = shift;
    my ( $personnel ) = shift;
    return unless $self->can( 'client_id' ) and $self->client_id;

    return if $personnel and not $personnel->primary_role->has_client_permissions( $self->client_id );

    require eleMentalClinic::Client;
    my $client = eleMentalClinic::Client->new({ client_id => $self->client_id })->retrieve;
    return unless $client->id;
    return $client;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub clone {
    my $self = shift;

    die 'Clone does not work with Client objects.'
        if ref $self =~ /Client$/;

    my $clone = $self->new( $self );
    my $key = $self->primary_key;

    $clone->$key( '' );
    $clone->save;
    $clone;
}


=head2 build_db_accessors

Class method.

Generate db-related accessors.

=cut

my %done;

sub build_db_accessors {
    my $class = shift;
    for (@{ $class->fields || [] }) {
        next if $done{$class}{$_}{attribute}++;
        eleMentalClinic::Base::attribute($class, $_);
    }
    $class->build_one_to_one_accessors;
    $class->build_one_to_many_accessors;
}

=head2 accessors_retrieve_one()

Class method.

Defines accessors to automatically create for the calling package.

Should define a data structure like:

    {
        method_name => { foreign_key => foreign_package },
    }

This creates a "method_name()" method in __PACKAGE__ which returns the one
C<foreign_package> object whose primary key matches the C<foreign_key> of the
current object.

More concretely, from L<eleMentalClinic::Billing::Prognote>

    {
        prognote => { prognote_id => 'eleMentalClinic::ProgressNote' },
    }

This creates a "prognote()" method in
L<eleMentalClinic::Financial::BillingPrognote> which returns the one
L<eleMentalClinic::ProgressNote> object whose primary key matches the
C<prognote_id> of the current object.

=head2 build_one_to_one_accessors

Class method.

Generates accessors as defined by C<accessors_retrieve_one>.

=cut

sub build_one_to_one_accessors {
    my $class = shift;

    my %one_to_one = %{ $class->accessors_retrieve_one };
    while( my( $method, $definition ) = each %one_to_one ) {
        next if $done{$class}{$method}{one_to_one}++;
        my( $id, $package ) = each %$definition;
        die "$class cannot $id"
            unless $class->can( $id );

        no strict 'refs';
        *{ "$class\::$method" } = sub {
            my $self = shift;
            croak 'Must call on stored object'
                unless $self->$id;
            return $package->retrieve( $self->$id );
        };
    }
}

=head2 accessors_retrieve_many()

Class method.

Defines accessors to automatically create for the calling package.

Should define a data structure like:

    {
        method_name => { foreign_key => foreign_package },
    }

This creates a "method_name()" method in __PACKAGE__ which returns every
C<foreign_package> object whose C<foreign_key> field matches the primary key of
the current object.

More concretely, from L<eleMentalClinic::ProgressNote>

    {
        billing_prognotes   => { prognote_id => 'eleMentalClinic::Financial::BillingPrognote' }
    }

This creates a "billing_prognotes()" method in L<eleMentalClinic::ProgressNote>
which returns every L<eleMentalClinic:Financial::BillingPrognote> object whose
C<prognote_id> field matches the C<rec_id> key of the current
L<eleMentalClinic::ProgressNote> object.

=head2 build_one_to_many_accessors

Class method.

Generates accessors as defined by C<accessors_retrieve_many>.

=cut

sub build_one_to_many_accessors {
    my $class = shift;
    my %one_to_many = %{ $class->accessors_retrieve_many };
    while( my( $method, $definition ) = each %one_to_many ) {
        next if $done{$class}{$method}{one_to_many}++;
        my( $id, $package ) = each %$definition;
        die "$package cannot $id"
            unless grep /^$id$/ => @{ $package->fields }
            or $package->can( $id );

        no strict 'refs';
        *{ "${ class }::$method" } = sub {
            my $self = shift;
            die 'Must call on stored object'
                unless $self->id;
            return $package->get_by_( $id, $self->id );
        };
    }
}

# defaults:

sub table                   { '' }
sub fields                  { [] }
sub fields_required         { [] }
sub primary_key             { '' }
sub accessors_retrieve_one  { {} }
sub accessors_retrieve_many { {} }

1;
