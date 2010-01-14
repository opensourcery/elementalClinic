package eleMentalClinic::Base::Note;
use strict;
use warnings;

use base qw/ eleMentalClinic::DB::Object /;
use eleMentalClinic::Util;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_uncommitted_by_writer( $writer_id )

Class method.

Returns a list of progress note objects that are (a) associated with the given
writer, and (b) not committed.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub list_uncommitted_by_writer {
    my $class = shift;
    my( $writer_id ) = @_;

    die 'Writer id is required'
        unless $writer_id;
    dbquoteme( \$writer_id );
    my $notes = $class->db->select_many(
        $class->fields,
        $class->table,
        qq/
            WHERE data_entry_id = $writer_id
            AND( note_committed = 0 OR note_committed IS NULL )
        /,
        'ORDER BY start_date DESC, rec_id'
    );
    return $notes if $notes;
}

sub get_uncommitted_by_writer {
    my $class = shift;
    my $notes = $class->list_uncommitted_by_writer( @_ );

    # Legacy, return undef if no results.
    my $out = [ map{ $class->new( $_ )} @$notes ];
    return unless @$out;
    return $out;
}

1;
