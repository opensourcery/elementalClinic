var PREVIOUS_SECTION_ID
var EDIT_URL

$( document ).ready( function() {
    PREVIOUS_SECTION_ID = OSC.id_from( $( 'dl.assessment_section:first' ))
    EDIT_URL = $( 'a.edit_this' ).attr( 'href' )
    $( '.navigation li.section_selector a' ).click( function() { return show_section( OSC.id_from( $( this ))) })
    $( '#new_section_trigger a' ).click( function() { return new_section_display() })
    $( '#new_section_cancel' ).click( function() { return new_section_cancel() })
    $( '#new_section_create' ).click( function() { return new_section_create() })
    add_new_field_triggers()
    add_remove_field_triggers()
    add_section_labels_triggers()
})

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * everything below should be subroutines, not jquery triggers
 */
function show_section( id ) {
    PREVIOUS_SECTION_ID = id
    $( 'ul.navigation li' ).removeClass( 'current' )
    $( '.assessment_section' ).hide()

    $( '#section_selector_'+ id ).parent().addClass( 'current' )
    $( '#section_fields_'+ id ).show()

    $( '#part_id' ).attr('value', id )

    $( 'a.edit_this' ).attr( 'href', EDIT_URL+";part_id="+id );

    add_new_field_triggers()

    return false
}

function add_new_field_triggers() {
    // make sure there is not more than 1 click event bound to each object.
    $( '.new_field a' ).unbind() 
    $( '.new_field a' ).click( function() { return add_field( $( this )) })
}

function add_remove_field_triggers() {
    $( '.section_field a' ).click( function() {
        $( this ).parent().parent().remove()
        return remove_field( $( this ))
    })
}

function add_section_labels_triggers() {
    $( 'dl.assessment_section dd.label input' ).keyup( function( e ) {
        var k = e.which // key code
        if( k == 13 ) { return false }  // capture enter key
        if(    ( k >= 65 && k <= 90 )   // A-Z
            || ( k >= 97 && k <= 122 )  // a-z
            || ( k >= 48 && k <= 57 )   // 0-9
            || k == 32                  // space
            || k == 8                   // backspace
            || k == 45                  // -
            || k == 46                  // .
            || k == 58                  // :
        ) {
            var target = $( e.target )
            var id = OSC.id_from_parent( target.parent())
            $( '#section_selector_'+ id ).text( target.attr( 'value' ))
        }
    })
}

function add_field( trigger ) {
    var section_id = OSC.id_from_parent( trigger )

    $.get( '/admin_assessment_templates.cgi?op=_field;section_id='+ section_id, function( data ) {
        trigger.parent().replaceWith( data )
        add_new_field_triggers()
        add_remove_field_triggers()
        add_section_labels_triggers()
        /* FIXME  next_position is no longer provided by the function, can it be obtained from ajax 'data'?
        $( '#section_'+ section_id +'_field_'+ next_position ).focus()
        $( '#section_'+ section_id +'_field_'+ next_position ).keypress( function( e ) {
            if( e.which == 13 ) { return false } // capture enter key
        })
        */
    })
    return false
}

function remove_field( trigger ) {
    var section_id = trigger.attr( 'section_id' )
    var my_position = trigger.attr( 'position' )

    $.get( '/admin_assessment_templates.cgi?op=_field_remove;section_id=' + section_id +';position='+ my_position )
    return false
}

function new_section_display() {
    $( 'ul.navigation li' ).removeClass( 'current' )
    $( '.assessment_section' ).hide()

    $( '#new_section_trigger' ).addClass( 'current' )
    $( '#new_section' ).show()
    $( '#new_section_label' ).focus()

    return false
}

function new_section_cancel() {
    show_section( PREVIOUS_SECTION_ID )
    return false
}

/*
* validation
* send AJAX request
* parse response
* insert content into page
*/
function new_section_create() {
    var assessment_id = $( '#assessment_id' ).attr( 'value' )
    var label = $( '#new_section_label' ).attr( 'value' )
    var position = $( 'li.section_selector' ).length + 1

    $.get( '/admin_assessment_templates.cgi', {
        op              : '_section',
        assessment_id   : assessment_id,
        label           : label,
        position        : position,
        }, function( json ) {
            $( '#new_section_trigger' ).before( json.navigation )
            $( '#new_section' ).before( json.content )
            $( '.navigation li.section_selector a' ).click( function() { return show_section( OSC.id_from( $( this ))) })
            show_section( json.section_id )
            $( '#new_section_label' ).attr( 'value', '' )
            $( '#new_section_label' ).blur()
        },
        "json"
        )


    return false
}

