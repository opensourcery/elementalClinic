/* 
 * Copyright 2006,2007 OpenSourcery, LLC.  This program is free software, licensed under the terms of the GNU General Public License.  Please see the COPYING file in this distribution for more information, or see http://www.gnu.org/copyleft/gpl.html
 *
 * This file contains common helper code for jQuery.
 */

// namespace:  OpenSourceryCommon
var OSC = new Object()

// id from ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// snarfs the id from a string as the string after the last underscore.  e.g.,
// - date_123     : returns "123"
// - foo_bar_baz  : returns "baz"
OSC.id_from = function( element ) {
    if( ! element.attr( 'id' )) return false
    var parts = element.attr( 'id' ).split( '_' )
    return parts[ parts.length - 1 ]
}

// id from parent ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// like id_from, but traverses up an element's parents until it finds one with an id
OSC.id_from_parent = function( element ) {
    if( ! element.parent().html() ) { // XXX must be a better way to do this
        return false
    }
    var id = OSC.id_from( element )
    if( id ) {
        return id
    }
    else {
        return OSC.id_from_parent( element.parent() )
    }
}

OSC.autofocus = function() {
    $( '.autofocus' ).focus()
}

OSC.debug = function( value ) {
    OSC._initialize_debug()
    $( '#debug' ).append( '<li>'+ value +'</li>' )
}

OSC._initialize_debug = function() {
    if( ! OSC.DEBUG ) { return false }
    if( $( '#debug' ).size() > 0 ) { return true }
    $( 'body' ).append( '<ul id="debug"></ul>' )
    return true
}
