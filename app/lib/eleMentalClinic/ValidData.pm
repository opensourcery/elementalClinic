# vim: ts=4 sts=4 sw=4
package eleMentalClinic::ValidData;
use strict;
use warnings;

=head1 NAME

eleMentalClinic::ValidData

=head1 SYNOPSIS

Logic for lookup table elements.

=head1 METHODS

=cut

use base 'eleMentalClinic::DB::Object';
use Data::Dumper;
use Carp;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
    sub primary_key { 'rec_id' }
    sub methods { [ qw/ dept_id tables /] }
    sub fields { }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub init {
    my $self = shift;
    my $class = ref $self;
    my( $args ) = @_;

    $self->SUPER::init( $args );

    #FIXME - (Josh's question) isn't this assignment redundant from the $self->SUPER::init call? - ah, no, because dept_id is not a field.  Should it be?
    $self->dept_id( $args->{ dept_id });
    confess "Department ID (dept_id) is required" unless $self->dept_id;

    $self->tables( $self->list( 'valid_data_valid_data' ));
    return $self;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub table_names {
    my $self = shift;

    my @table_names;
    for( @{ $self->tables } ){
        push @table_names => $_->{ name };
    }
    return \@table_names;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns all the columns for the table, as an arrayref
sub column_names {
    my $self = shift;
    my $table = shift;
    my( @columns, $extra );

    $extra = $self->db->select_one(
        [ 'extra_columns' ],
        'valid_data_valid_data',
        "name = '$table'",
    ) unless $table eq 'valid_data_valid_data';
  
    @columns = qw/ rec_id dept_id name description active /;

    if( $extra and $extra->{ extra_columns } ){
         push @columns => split( ', ' => $extra->{ extra_columns } );
    }

    push( @columns, 'is_default' ) if $self->has_default( $table );
    
    return \@columns;
}
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns an arrayref of the extra columns if there are any
sub extra_columns {
    my $self = shift;
    my $table = shift;
    
    my $extra = $self->db->select_one(
        [ 'extra_columns' ],
        'valid_data_valid_data',
        "name = '$table'",
    ) unless $table eq 'valid_data_valid_data';
    
    my @columns;
    if( $extra and $extra->{ extra_columns } ){
        push @columns => split ( /\s*,\s*/, $extra->{ extra_columns });
    }

    return \@columns;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check if the table has a default or not.
sub has_default {
    my $self = shift;
    my ($table) = @_;

    return if $table eq 'valid_data_valid_data';

    my $result = $self->db->select_one(
        [ 'has_default' ],
        'valid_data_valid_data',
        "name = '$table'",
    );
    return unless $result;
    return $result->{ has_default };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get the default value for the table.
sub get_default {
    my $self = shift;
    my ( $table, $use_id ) = @_;
    my $column = $use_id ? 'rec_id' : 'name';
    
    $table = "valid_data$table";

    return unless $self->has_default( $table );

    my $default = $self->db->select_one(
        [ $column ],
        $table,
        "is_default = 1",
    );

    return unless $default;
    return $default->{ $column };
}
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns all the data, as arrayref of hashrefs, for specified table
# if $all is true, all are returned regardless of "active" flag
sub list {
    my $self = shift;
    my( $table, $all ) = @_;
    return unless $table and $table eq 'valid_data_valid_data' or $table = $self->is_table( $table );

    $all = $all
        ? ''
        : ' AND active = 1 '; 

    my $columns = $self->column_names( $table );

    my $results = $self->db->select_many(
        $columns,
        $table,
        "WHERE dept_id = ". $self->dept_id
        . $all .
        'ORDER BY name',
    );
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns names only, as arrayref, for specified table
# if $all is true, all are returned regardless of "active" flag
sub list_names {
    my $self = shift;
    my( $table, $all ) = @_;
    return unless $table and $table eq 'valid_data_valid_data' or $table = $self->is_table( $table );

    my $list = $self->list( $table, $all );
    my @names;
    for( @$list ) {
        push @names => $_->{ name }
    }
#     return \@names;
    return @names ? \@names : undef;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get {
    my $self = shift;
    my( $table, $id ) = @_;
    return unless $table = $self->is_table( $table );
    return unless $id;

    my $columns = $self->column_names( $table );

    my $results = $self->db->select_one(
        $columns,
        $table,
        "dept_id = ". $self->dept_id
        . " AND rec_id = $id",
    );
    return $results;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_name {
    my $self = shift;
    my( $table, $id ) = @_;

    my $vd = $self->get( $table, $id );
    $vd->{ name };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_desc {
    my $self = shift;
    my( $table, $id ) = @_;

    my $vd = $self->get( $table, $id );
    $vd->{ description };
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# only table and name are required
# dept_id comes from the object, description is optional
# returns the rec_id of the inserted row
sub save {
    my $self = shift;
    my( $table, $item ) = @_;
    return unless $table = $self->is_table( $table );
    return unless $item->{ name };

    if( $item->{ description } ){
        $item->{ description } =~ s/\n/\\n/g;
        $item->{ description } =~ s/\r//g;
    }


    my @columns = qw/ name description active /;
    push @columns => @{$self->extra_columns( $table )};

    if ( $self->has_default( $table ) ) {
        push (@columns, 'is_default' );
        $item->{ is_default } = 0 unless $item->{ is_default };
        #Only one default can be set.
        $self->db->do_sql(
                "UPDATE $table SET is_default = 0",
                'no return'
        ) if $item->{ is_default };
    }

    my $db_op;
    my @params;
    my $id = $item->{ rec_id };

    if ( $id ) {
        $item->{ active } ||= 0;
        $db_op = 'update_one';
        push( @params, "rec_id = $id" );
    }
    else {
        $item->{ active } = 1;
        $db_op = 'insert_one';
    }

    $item->{ dept_id } = $self->dept_id;
    my $to_save = { map { $_ => $item->{ $_ }} @columns, 'dept_id' };

    @params = (
        $table,
        [ keys %$to_save ],
        [ values %$to_save ],
        @params,
    );

    #Params is seperate for debugging purposes.
    #use Data::Dumper;
    #print Dumper( \@params );

    my $result = $self->db->$db_op( @params );
    $item->{ rec_id } = $result unless $id;

    return $item;
}

sub copy_and_save {
    my $self = shift;
    my ( $table, $item ) = @_;
    Carp::croak "Not a valid_data table: $table"
        unless $table = $self->is_table( $table );
    Carp::croak "Not a valid item to save for $table (no name)"
        unless $item->{name};

    # pass new objects through to save
    return $self->save( $table, $item ) unless $item->{rec_id};

    $self->db->transaction_do(sub {
        my $current = $self->get( $table, $item->{rec_id} );

        # gross special case -- the DB may contain undef, but we want that to
        # be treated the same as 0 (which is what the controller will pass in)
        $_->{is_default} ||= 0 for $item, $current;

        my @changes = grep { 
            exists $item->{$_} and
            defined $item->{$_}
            ? (!defined $current->{$_} or $current->{$_} ne $item->{$_})
            : defined $current->{$_}
        } keys %$current;
        return $current if @changes == 0;
        if (@changes == 1 and $changes[0] eq 'active') {
            return $self->save( $table, $item );
        }
        # if anything other than 'active' is changing, we need to deactivate
        # (if necessary) the current entry and save a new copy
        $self->save( $table, { %$current, active => 0 } );
        $item = 
        $self->save( $table, { %$item,    rec_id => undef } );
    });
    return $item;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# returns the table name if there's a match, undef otherwise
# a '_' prefix to the incoming name implies 'valid_data'
# thus, '_table' will be expanded to 'valid_data_table' for matching
# this corrected name is returned, so you should always use the return
# value of this method as the correct table name
sub is_table {
    my $self = shift;
    my( $name ) = @_;
    return unless $name;

    $name = "valid_data$name" if $name =~ /^_/;
    return grep( /^$name$/, @{ $self->table_names })
        ? $name
        : undef;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_table {
    my $self = shift;
    my( $table ) = @_;
    return unless $table = $self->is_table( $table );

    $self->db->select_one(
        [ qw/ rec_id dept_id name description readonly extra_columns /],
        'valid_data_valid_data',
        "dept_id = ". $self->dept_id
        . " AND name = '$table'",
    );
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub get_byname {
    my $self = shift;
    my( $table, $name ) = @_;
    return unless defined $table and $name;
    return unless $table = $self->is_table( $table );

    my $columns = $self->column_names( $table );

    return unless my $vd = $self->db->select_one(
        $columns,
        $table,
        "name = '$name' and active=1"
    );
    return $vd;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_name_desc_list( $table )

Object method. Returns a list of the valid_data records, with 
the name and description in this form: "name: description".

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub get_name_desc_list {
    my $self = shift;
    my( $table ) = @_;

    my $list = $self->list( $table );
    return unless $list;

    my @formatted = sort { $a->{ rec_id } <=> $b->{ rec_id } } @$list;

    @formatted = map {
        $_->{ name_desc } = $_->{ name } if $_->{ name };
        $_->{ name_desc } .= ": $_->{ description }" if $_->{ description };
        $_;
    } @formatted;

    return \@formatted;
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
