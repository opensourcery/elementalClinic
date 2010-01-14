$( document ).ready( function() {
    // attaching triggers
    $( 'p.program_name a' ).click( function() {
        return toggle_episode( OSC.id_from_parent( $( this )) )
    })
    // new program
    $( '#show_new_program a.local' ).click( function() { return show_new_( 'program' ) })
    $( 'a.cancel_new_program' ).click( function() { return cancel_new_( 'program' ) })

    // new event
    $( '.show_new_event a.local' ).click( function() { return show_new_( 'event', $( this )) })
    $( 'a.cancel_new_event' ).click( function() { return cancel_new_( 'event', $( this )) })

    // new discharge
    $( '.show_new_discharge a.local' ).click( function() { return show_new_( 'discharge', $( this )) })
    $( 'a.cancel_new_discharge' ).click( function() { return cancel_new_( 'discharge', $( this )) })

    // new primary
    $( '.show_new_primary a.local' ).click( function() { return show_new_( 'primary', $( this )) })
    $( 'a.cancel_new_primary' ).click( function() { return cancel_new_( 'primary', $( this )) })

    // expand/collapse
    $( '#expand_all' ).click( function() { return toggle_all_episodes( true ) })
    $( '#collapse_all' ).click( function() { return toggle_all_episodes( false ) })

    // activate primary program when loading placement screen
    $( 'li.primary p.program_name a' ).click()
})

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * everything below should be subroutines, not jquery triggers
 */
function toggle_episode( id, force ) {
    if( force == undefined ) {
        $( 'li#episode_'+ id ).hasClass( 'current' )
            ? hide_episode( id )
            : show_episode( id )
    }
    else {
        force
            ? show_episode( id )
            : hide_episode( id )
    }
    return false
}

function show_episode( id ) {
    $( 'div#episode_details_'+ id ).slideDown( 'fast' )
    $( 'li#episode_'+ id ).addClass( 'current' )
}

function hide_episode( id ) {
    $( 'div#episode_details_'+ id ).slideUp( 'fast' )
    $( 'li#episode_'+ id ).removeClass( 'current' )
}

// new form manipulation
function show_new_( type, element ) {
    if( element ) {
        if( element.parent().hasClass( 'active' )) return false
        var id = OSC.id_from_parent( element )
        cancel_new_( 'event', element )
        cancel_new_( 'discharge', element )
        cancel_new_( 'primary', element )
        element.parent().addClass( 'active' )
    }
    var type_id = ( id )
        ? type +'_'+ id
        : type
    $( '#create_new_'+ type_id ).slideDown( 'fast' )
    return false
}

function cancel_new_( type, element ) {
    if( element ) var id = OSC.id_from_parent( element )
    var type_id = ( id )
        ? type +'_'+ id
        : type
    $( '#show_new_'+ type_id ).removeClass( 'active' )
    $( '#create_new_'+ type_id ).slideUp( 'fast' )
    return false
}

function toggle_all_episodes( force ) {
    $( 'p.program_name a' ).each( function() {
        toggle_episode( OSC.id_from_parent( $( this )), force )
    })
    return false
}
