#!/usr/bin/perl
# vim: ts=4 sts=4 sw=4
use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use Venus::Mechanize;

my $mech = Venus::Mechanize->new_with_server;

$mech->admin_login_ok;

# patient search page
$mech->follow_link_ok( { text => 'Patients' }, 'patient search home' );
$mech->content_contains( 'Please select a client', 'no client selected' );

# XXX this doesn't really test the interface because mech can't do javascript
# the 'Patient Search' box only works with javascript, and I don't want to
# write an interface just for mech to use -- that'd be as bad as this
# workaround AND involve extra otherwise-useless code.
# so this just simulates what the javascript would do, which means it knows
# "too much" about what fields to fill out and so on.
$mech->post_ok(
    $mech->uri_for(
        '/clientoverview.cgi',
    ),
    {
        op => 'home',
        client_id => 1001, # Miles Davis
        view_client => 'View Client',
    },
    'client overview',
);

$mech->content_contains( 'Davis, Miles D', 'patient name' );

for my $link (
    # clone here so that when $mech deletes the tree, the links don't go away
    map { $_->clone } 
    # oh, how I long for jquery: '#client_id ul li a'
    map { $_->look_down(_tag => 'a') }
    $mech->tree
    ->look_down(id => 'client_head')
    ->look_down(_tag => 'ul')
    ->look_down(_tag => 'li')
) {
    my $uri   = URI->new( $link->attr('href') );
    my $label = ($uri->path_segments)[-1];
    $label =~ s/\.cgi$//;
    eval {

        # the eval/or is so that this is always 2 tests, whether or not get_ok dies
        # (as it will on an internal server error)
        eval {
            $mech->get_ok( $uri, "get $label" )
        }
        or is $@, "", "get $label: internal server error";
        
        ok(
            $mech->tree->look_down(id => 'client_content'),
            "content for $label",
        );

        # XXX this is pretty crude; I'll refactor it when I have a better idea of
        # how things should be laid out.
        my $t_class = "Venus::t::Mechanize::patients::$label";
        if ( eval "require $t_class; 1" ) {
            eval { $t_class->run($mech) };
            is $@, "", "no errors running $t_class";
        } else {
            die $@ unless $@ =~ /Can't locate .+ in \@INC/;
        }
    };
    is $@, "", "$label: no errors";
    $link->delete;
}
