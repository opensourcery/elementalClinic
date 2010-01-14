# vim: ts=4 sts=4 sw=4
package eleMentalClinic::Report::Plugin::Email;

use Moose;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use eleMentalClinic::Report::Labelled;
use namespace::autoclean;

with 'eleMentalClinic::Report::Plugin' => {
    type  => 'site',
    label => 'Outgoing Email',
    admin => 0,
    result_isa => ArrayRef,
};

with qw/
    eleMentalClinic::Report::HasDateRange
/;

has sort => (is => 'ro', isa => Str);
has order => (is => 'ro', isa => Str);
has search => (is => 'ro', isa => Str);
has contained_in => (is => 'ro', isa => ArrayRef[Str]);
# XXX fix this to use 'client_id' instead
has client => (is => 'ro', isa => Int);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 email()

Object method.

Parameters:
    {
        sort => 'date'/'client'/'address',
        order => 'ASC'/'DSC',
        search => 'Search String',
        contained_in => [ 'subject', 'address', 'body' ],
        start_date => DATE,
        end_date => DATE,
        client => 1001,
    }

Returns:
    [
        {
            email_id => 1001,
            subject => 'Message Subject',
            body => 'Message Body',
            send_date => 2008-11-14,
            sender_id => 1001, #Personnel table id.
            recipient_data => [
                {
                    client_id => 1001, # ***
                    fname => 'Bob', #Client first name ***
                    lname => 'Marley', #Client last name ***
                    email => 'bob@marley.com',
                    recipient_id => 1001,
                },
                {...},
            ],
        }
    ]
    Note: *** - May not always be present

 * When sorting by client Only items w/ client_id will be displayed.
 * When sorting by date messages with multiple recipients will be a single item w/ multiple client_data entrees
 * When sorting by address or client each item will only have a single client_data element.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub build_result {
    my ($self) = @_;

    my $sort = $self->sort;
    my $order = $self->order;
    my $mail_table = eleMentalClinic::Mail->table;
    my $recip_table = eleMentalClinic::Mail::Recipient->table;
    my $client_table = eleMentalClinic::Client->table;
    my $contains = $self->search;

    # This tells us what to search for and in what fields: field => string.
    return [] if ( $contains and not $self->contained_in );
    my $search = {};
    if ( my $contained_in = $self->contained_in ) {
        $contained_in = [ $contained_in ] unless ref $contained_in eq 'ARRAY';
        $search = { map { $_ => $contains } @$contained_in };
    }

    my $sql = <<EOT;
    SELECT
        r.email_id,
        r.client_id,
        r.rec_id as recipient_id,
        m.subject,
        m.body,
        m.send_date,
        m.sender_id,
        c.fname,
        c.lname,
        COALESCE( r.email_address, c.email) AS email
      FROM
                  $recip_table  AS r
        LEFT JOIN $mail_table   AS m ON(m.rec_id = r.email_id)
        LEFT JOIN $client_table AS c ON(r.client_id = c.client_id)
EOT

    # This maps each field to a table and operator for checking it.
    my $MAP = {
       #DB Field => [ 'table.', 'operator' ],
       #table. is so that you can leave it undefined and get email.
        start_date => [ 'm.send_date', '>=' ],
        end_date => [ 'm.send_date', '<=' ],
        subject => [ 'm.subject', 'ILIKE' ],
        body => [ 'm.body', 'ILIKE' ],
        sender_id => [ 'm.sender_id', '=' ],
        address => [ [ 'r.email_address', 'c.email' ] , 'ILIKE' ],
        client => [ 'r.client_id', '=' ],
    };

    my $where = [];
    my $params = [];
    my $orderby;

    # Check eac field to see if we care about it.
    while ( my ( $field, $value ) = each %$MAP ) {
        #Only continue if we care.
        next unless my $param =
            $self->can($field)
            ? $self->$field || $search->{$field}
            : $search->{$field};

        #Build the where clause
        my ( $columns, $operator ) = @$value;
        $columns = [ $columns ] unless ref $columns eq 'ARRAY';
        my $subwhere = [];
        for my $column ( @$columns ) {
            push( @$subwhere, "$column $operator ?" );
            push( @$params, ($operator =~ /LIKE/i) ? "%$param%" : $param );
        }
        push( @$where, join( ' OR ', @$subwhere ));
    }

    # If we are sorting by client then ignore messages w/o a client
    push( @$where, "r.client_id IS NOT null" ) if $sort eq 'client';

    # What are we sorting by, it will be one of these
    $orderby = " ORDER BY c.lname $order" if $sort eq 'client';
    $orderby = " ORDER BY m.send_date $order" if $sort eq 'date';
    $orderby = " ORDER BY email $order" if $sort eq 'address';

    # combine initial sql, where statements, and order, then run it.
    my $query = $sql;
    $query .= " WHERE " . join( ' AND ', @$where ) if @$where;
    $query .= $orderby;
    my $results = $self->db->do_sql( $query, undef, @$params );

    # recipient data and date format
    for my $result ( @$results ) {
        $result->{ recipient_data } = [{
            map { $_ => delete $result->{ $_ }} qw/email lname fname recipient_id client_id/
        }];
        ( $result->{ send_date } ) = split( ' ', $result->{ send_date });
    }

    # If we are sorting by date then we can group each 'recipient' by message.
    # Just put all the addresses into one result per message.
    if ( $sort eq 'date' ) {
        my $all = $results;
        $results = [];
        my $seen = {};
        for my $result ( @$all ) {
            my $mail_id = $result->{ email_id };
            if ( my $existing = $seen->{ $mail_id }) {
                push( @{ $existing->{ recipient_data }}, @{ $result->{ recipient_data }});
            }
            else {
                push( @$results, $result );
                $seen->{ $mail_id } = $result;
            }
        }
    }

    #This is what we're here for.
    return $results;
}


__PACKAGE__->meta->make_immutable;
1;
