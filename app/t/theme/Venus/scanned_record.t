# vim: ts=4 sts=4 sw=4

use strict;
use warnings;
use lib 't/lib';
use Venus::Mechanize;
use Test::More tests => 28;

my @files = (
    'sample_scan.1.jpg',
    'sample_scan.2.jpg'
);

# Find a file in the file selector
sub find_file {
    my($mech, $file) = @_;
    return $mech->tree->look_down(id => "file")->look_down(_tag => 'input', value => $file);
}

sub fresh_start_ok {
    my ( $mech, @files ) = @_;

    $mech->get_script_ok( 'scanned_record.cgi' );

    for my $file (@files) {
        ok(
            find_file($mech, $file),
            "found scanned record $file",
        );
    }
}

my $mech = Venus::Mechanize->new_with_server;

# use someone with admin=0 scanner=1
$mech->login_ok( 1, 'whip', 'cracker' );

fresh_start_ok( $mech, @files );

$mech->follow_link_and_return_ok(
    { text => $files[0] },
    'view scanned file',
);

is(
    $mech->tree->look_down(id => 'file_details')
               ->look_down(_tag => 'table')->as_trimmed_text,
    '',
    'no history yet',
);

# javascript for choosing a client means I have to fake a form submission
$mech->post_ok(
    $mech->form_name( 'scanned_record_form' )->action,
    {
        client_id => 1001,
        description => 'a scanned file',
        op => 'Associate File with Patient',
        filename => $files[0],
    },
    'fake form post',
);

# Is the associated file gone from the list?
ok(
    find_file($mech, $files[1]),
    "found scanned record $files[1]",
);
ok(
    !find_file($mech, $files[0]),
    "associated file no longer in list",
);


my @history = $mech->tree->look_down(id => 'file_details')
    ->look_down(_tag => 'table')->look_down(_tag => 'tr');
is( @history, 1, 'one history item' );
my @tds = $history[0]->look_down(_tag => 'td');
is_deeply(
    [
        $tds[0]->as_trimmed_text,
        ($tds[1]->content_list)[0]->attr('alt'),
    ],
    [
        'Miles Davis',
        $files[0],
    ],
    'history item contents',
);

$mech->get_and_return_ok(
    ($tds[1]->content_list)[0]->attr('src'),
    'get scanned file img',
);

$mech->follow_link_ok(
    { text => 'Miles Davis' },
    'client scanned record list',
);

$mech->follow_link_ok(
    { text => 'a scanned file' },
    'client scanned record',
);

$mech->submit_form_ok(
    {
        form_name => 'scanned_record_desc_form',
        fields => {
            description => 'a scammed file',
        },
        button => 'op',
    },
    'change record description',
);

$mech->follow_link_ok(
    { text => 'a scammed file' },
    'name changed',
);

$mech->follow_link_and_return_ok(
    { text => $files[0] },
    'view scanned record',
);

$mech->submit_form_ok(
    {
        form_name => 'client_scanned_record_form',
        button => 'op',
    },
    'wrong patient',
);

is(
    $mech->tree->look_down( id => 'file_list' )->as_trimmed_text,
    'The patient has no scanned files.',
    'no files',
);


fresh_start_ok( $mech, @files );

# Reassociate both files
for my $file (@files) {
    $mech->post_ok(
        $mech->form_name( 'scanned_record_form' )->action,
        {
            client_id => 1001,
            description => 'a scanned file',
            op => 'Associate File with Patient',
            filename => $file,
        },
        'fake form post',
    );
}


# Now the list is empty
$mech->content_contains( 'No scanned files.' );

# Check history contains both items
{
    my @history = $mech->tree->look_down(id => 'file_details')
                             ->look_down(_tag => 'table')
                             ->look_down(_tag => 'tr');
    is( @history, 2, 'two history items' );
}


fresh_start_ok( $mech );
