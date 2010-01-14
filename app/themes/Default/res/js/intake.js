$( document ).ready( function() {
    // referral fields
    toggle_referral_fields( false )
    $( '#is_referral_0' ).click( function() {
        toggle_referral_fields( false )
    })
    $( '#is_referral_1' ).click( function() {
        toggle_referral_fields( true )
    })

    // intake AJAX
    // step 2
    $( '#no_address' ).change( function() { return toggle_field_sets('address') })
    $( '#no_phone' ).change( function() { return toggle_field_sets('phone') })
    $( '#no_emergency' ).change( function() { return toggle_field_sets('emergency') })
    toggle_field_sets('address')
    toggle_field_sets('phone')
    toggle_field_sets('emergency')
    add_address_trigger()
    add_phone_trigger()
    add_emergency_contact_trigger()
    hide_selectors()

    // step 3, toggle employer on and off
    $( '#no_employment' ).change( function() { return toggle_field_sets('employment') })
    toggle_field_sets('employment')

    // step 4, toggle treater on and off
    $( '#no_treater' ).change( function() { return toggle_field_sets('treater') })
    toggle_field_sets('treater')
})

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * everything below should be subroutines, not jquery triggers
 */
function hide_selectors() {
    var classes = new Array( '.phone_selector', '.address_selector', '.emergency_selector' )
    for(i in classes) {
        if ( $( classes[i] ).size() == 1 ) {
            $( classes[i] ).each( function(){
                $( this ).hide()
            })
        }
    }
}

function toggle_field_sets(clss) {
    if( $( '#no_' + clss ).attr( 'checked' )) {
        $( '.client_' + clss ).addClass( 'inactive' )
        $( '.client_' + clss + ' input' ).attr( 'disabled', true )
        $( '.client_' + clss + ' input' ).each( function(){
            if( $( this ).hasClass( 'required' )) {
                $( this ).removeClass( 'required' )
                $( this ).addClass( 'x_req' )
            }
        })
    }
    else {
        $( '.client_' + clss ).removeClass( 'inactive' )
        $( '.client_' + clss + ' input' ).attr( 'disabled', false )
        $( '.client_' + clss + ' input' ).each( function(){
            if( $( this ).hasClass( 'x_req' )) {
                $( this ).addClass( 'required' )
                $( this ).removeClass( 'x_req' )
            }
        })
    }
}

function add_address_trigger() {
    $( 'p.add.address a' ).click( function() { return add_address( $( this )) })
}

function add_phone_trigger() {
    $( 'p.add.phone a' ).click( function() { return add_phone( $( this )) })
}

function add_emergency_contact_trigger() {
    $( 'p.add.emergency_contact a' ).click( function() { return add_emergency_contact( $( this )) })
}

function add_address( element ) {
    var ordinal = OSC.id_from_parent( element )
    $.get( '/intake.cgi?op=_address;ordinal='+ ordinal, function( data ) {
        element.remove()
        $( '#client_addresses' ).append( data )
        add_address_trigger()
    })
    $( '.address_selector' ).show()
    return false
}

function add_phone( element ) {
    var ordinal = OSC.id_from_parent( element )
    $.get( '/intake.cgi?op=_phone;ordinal='+ ordinal, function( data ) {
        element.remove()
        $( '#client_phones' ).append( data )
        add_phone_trigger()
    })
    $( '.phone_selector' ).show()
    return false
}

function add_emergency_contact( element ) {
    var ordinal = OSC.id_from_parent( element )
    $.get( '/intake.cgi?op=_emergency_contact;ordinal='+ ordinal, function( data ) {
        element.remove()
        $( '#client_emergency_contacts' ).append( data )
        add_emergency_contact_trigger()
    })
    $( '.emergency_selector' ).show()
    return false
}

function toggle_referral_fields( is_referral ) {
    if( is_referral ) {
        $( '#referral_fields' ).show()
        $( '#admit_button' ).attr( 'value', 'Admit client as a referral' )
    }
    else {
        $( '#referral_fields' ).hide()
        $( '#admit_button' ).attr( 'value', 'Admit client' )
    }
}
