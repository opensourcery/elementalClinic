=pod

eleMentalClinic::Migration - Database Migrations that are sane

It's best to use the elementalclinic_migration tool to leverage the functionality in here.

=head1 METHODS

=cut

package eleMentalClinic::DB::Migration;
use strict;
use warnings;
use File::Temp;

use eleMentalClinic::DB;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 new()

Constructor. No arguments.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub new {
    my $self = bless { }, shift;
    $self->{db} = new eleMentalClinic::DB;
    $self->{dbh} = $self->{db}->dbh;

    $self->init;

    return $self;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 init()

Init method for constructor. No arguments.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub init {
    my $self = shift;

    my $version = $self->get_version;

    unless ($version) {
        unless (
          $self->dbh->table_info('%', '%', 'migration_information', '')
          ->fetchrow_arrayref
        ) {
            my $sth = $self->dbh->prepare('create table migration_information (version integer not null, date integer not null)');
            $sth->execute;
            $sth->finish;
        }

        my $sth = $self->dbh->prepare('insert into migration_information (version, date) values (0, ?)');
        $sth->execute(time);
        $sth->finish;
    }
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 dbh()

Get the database handle.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub dbh { $_[0]->{dbh} }


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 get_version()

Gets what the database thinks it's version is. Takes no arguments.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub get_version {
    my $self = shift;

    my $sth = $self->dbh->prepare('select version from migration_information limit 1');

    eval {
        $sth->execute;
    };

    if ($@) {
        return undef;
    }

    my $version = ($sth->fetchrow_array)[0];

    $sth->finish;

    return $version;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 update_version($version)

Takes a version argument and sets the database to that version.

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub update_version {
    my ($self, $version) = @_;

    my $sth = $self->dbh->prepare('update migration_information set version=?, date=?');
    $sth->execute($version, time);
    $sth->finish;
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 migrate(%args)

Migrates a directory of sql files that are prefixed with numbers (e.g.,
101stuff.sql) in order. For "downgrading" operations, *.sql.down files are
consulted in reverse order. The highest number (lowest when downgrading) will
be consulted regardless of the target specified with to_version.

Arguments:

    up           => 1/0 - migrate the database up or down
    to_version   => int - target to migrate to.
    from_version => int - override the database version to migrate from.
    dir          => str - directory containing the schema files.
    tag          => str - migration tag to run

For the C<tag> argument, the default is an empty string if C<up> is true (the
default) and C<down> if C<up> is false.  It specifies a suffix for migration
files that must be present.  For example:

    # run 10foo.sql 20bar.pl
    { up => 1, tag => '' }
    { up => 1 }
    { }

    # run 20bar.pl.down 10foo.sql.down
    { up => 0, tag => 'down' }
    { up => 0 }

    # run 10foo.sql.upgrade 20foo.sql.upgrade
    { up => 1, tag => 'upgrade' }
    { tag => 'upgrade' }

It may also be an arrayref of suffixes:

    # run 10foo.sql, 15foo.sql.upgrade, and 20bar.pl
    { up => 1, tag => [ '', 'upgrade' ] }

=cut

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub migrate { 
    my ($self, %arg) = @_;

    $arg{up} = $arg{up} ? 1 : 0;
    $arg{dir} ||= 'database/schema';
    exists $arg{tag} or $arg{tag} = $arg{up} ? '' : 'down';
    $arg{tag} = [ 
        $arg{tag},
        @{ delete $arg{extra_tag} || [] }
    ];

    unless ( defined $arg{from_version} ) {
        $arg{from_version} = $self->get_version;

        unless ( defined $arg{from_version} ) {
            $self->update_version(0);

            $arg{from_version} = $self->get_version;
        }
    }

    my @files = $self->migration_files( %arg );

    my $config = eleMentalClinic::Config->new->stage1;

    my ($db_user, $db, $db_port ) = @ENV{qw(DB_USER DB DB_PORT)};
    $db_user         ||= $config->dbuser;
    $db              ||= $config->dbname;
    $db_port         ||= $config->port;

    my $pgpassfile = File::Temp->new;
    $pgpassfile->print(
        join(":",
            $config->host,
            $db_port,
            $db,
            $db_user,
            $config->passwd,
        ),
        "\n",
    );
    $pgpassfile->flush;
    $ENV{PGPASSFILE} = $pgpassfile;

    my $sqlparams = "-d $db";
    $sqlparams .= " -U $db_user" if ( $db_user );
    $sqlparams .= " -p $db_port" if ( $db_port );
    $sqlparams .= " -h " . $config->host;

    for my $file (@files) {
        my $path = $file->[1];

        my ($type) = $path =~ /\.(sql|pl)/;

        print "# Processing schema '$path'...\n";

        if ( $type eq 'sql' ) {
            my $output = qx(psql -q $sqlparams -f "$path" 2>&1);
            if ($output =~ /ERROR:/ or $output =~ /could not connect/) {
                die "Error during migration -- aborting: $output";
            }
        } elsif ( $type eq 'pl' ) {
            unless ( do $path ){
                die "Can't compile $path: $@" if $@;
                die "Can't read $path: $!" if $!;
            }
        } else {
            die "unhandled migration type: $type (from $path)";
        }
        print "# done.\n";
    }
    if (@files) { 
        no warnings;
        print "# Updating Version to $files[-1]->[0]...\n";
        $self->update_version($files[-1]->[0]);
        use warnings;
        print "# done.\n";
    } else {
        print "# No files updated, not updating version.\n";
    }

    1;
}

sub migration_files {
    my $self = shift;
    my ( %arg ) = @_;

    my $to_version   = $arg{to_version};
    my $from_version = $arg{from_version};
    my $dir          = $arg{dir};

    opendir(DIR, $dir) || die "Couldn't open $dir: $!";

    my @files;
    my @match = map { 
        $_ 
        ? qr/\.(sql|pl)\Q.$_\E$/
        : qr/\.(sql|pl)$/;
    } @{ $arg{tag} };

    # read the directory and get the files we need
    foreach my $file (readdir(DIR)) {
        next if (-d $file || $file =~ /^\./);
        next unless grep { $file =~ $_ } @match;

        push @files, $file;
    }

    closedir(DIR);

    @files = map { [ /^(\d+)/, "$dir/$_" ] } @files;
    @files = $arg{up} ? $self->sort_up(@files) : $self->sort_down(@files);

    my ($min, $max) = $arg{up}
        ? ($from_version + 1, $to_version)
        : ($to_version + 1, $from_version);
    $min ||= 0;
    $max ||= 9999;

    @files = grep { 
        $_->[0] >= $min and
        $_->[0] <= $max
    } @files;

    return @files;
}

sub sort_up {
    my $self = shift;
    sort {
        $a->[0] <=> $b->[0] or
        $a->[1] cmp $b->[1]
    } @_;
}

sub sort_down {
    my $self = shift;
    sort {
        $b->[0] <=> $a->[0] or
        $b->[1] cmp $a->[1]
    } @_;
}

=head1 BUGS


=head1 AUTHOR

Chad Granum <chad@opensourcery.com>

Erik Hollensbe <erikh@opensourcery.com>

=head1 COPYRIGHT

(c) 2007 OpenSourcery, LLC. See additional provisions in the COPYING file with
this distribution.

=cut

1;
