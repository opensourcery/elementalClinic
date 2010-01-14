# vim: ts=4 sts=4 sw=4

use strict;
use warnings;
use lib 't/lib';
use Venus::Mechanize;
use Test::More tests => 22;

my $filename = 'sample_scan.1.jpg';

sub fresh_start_ok {
    my ( $mech ) = @_;

    $mech->get_script_ok( 'scanned_record.cgi' );

    ok(
        $mech->tree->look_down(_tag => 'img', alt => $filename),
        'found scanned record',
    );
    is(
        $mech->tree->look_down(id => 'file_details')
            ->look_down(_tag => 'table')->as_trimmed_text,
        '',
        'no history yet',
    );

    $mech->follow_link_and_return_ok(
        { text => $filename },
        'view scanned file',
    );
}

my $mech = Venus::Mechanize->new_with_server;

# use someone with admin=0 scanner=1
$mech->login_ok( 1, 'whip', 'cracker' );

fresh_start_ok( $mech );

# javascript for choosing a client means I have to fake a form submission
$mech->post_ok(
    $mech->form_name( 'scanned_record_form' )->action,
    {
        client_id => 1001,
        description => 'a scanned file',
        op => 'Associate File with Patient',
        filename => $filename,
    },
    'fake form post',
);

$mech->content_contains( 'No scanned files.' );

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
        $filename,
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
    { text => $filename },
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

fresh_start_ok( $mech );
