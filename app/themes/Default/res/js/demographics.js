var emcChooser = new Object

$( document ).ready( function() {
    emcChooser.chooser_bind( '#address_chooser', 'addr' )
    emcChooser.chooser_bind( '#phone_chooser', 'phn' )
})

emcChooser.select = function( id, prefix ) {
    var num = emcChooser.nameToVal( $(id).val() )
    num ? emcChooser.chooser_select( prefix, num )
        : emcChooser.new_obj()
}

emcChooser.new_obj = function() {
    $( '#op_edit' ).click();
}

emcChooser.nameToVal = function( name ) {
    var first = name.charAt(0)
    return first == 'P' ? 1
         : first == 'S' ? 2
         : first == 'T' ? 3
         : 0
}

emcChooser.chooser_bind = function( id, prefix ) {
    $( id + ' span.right' ).bind( 'click', function() {
        emcChooser.chooser_select( prefix, emcChooser.chooser_next( prefix ))
    })
    $( id + ' span.left' ).bind( 'click', function() {
        emcChooser.chooser_select( prefix, emcChooser.chooser_prev( prefix ))
    })
}

emcChooser.chooser_current = function( prefix ) {
    var label = $( 'fieldset.contact_chooser.' + prefix + ' span.label.selected' ).attr('id')
    var num = parseInt(label.charAt(label.length - 1))
    return num
}

emcChooser.chooser_next = function( prefix ) {
    var next = emcChooser.chooser_current( prefix ) + 1
    if ( next > 3 ) {
        next = 1
    }
    return next
}

emcChooser.chooser_prev = function( prefix ) {
    var prev = emcChooser.chooser_current( prefix ) - 1
    if ( prev < 1  ) {
        prev = 3
    }
    return prev
}

emcChooser.chooser_select = function( prefix, num ) {
    $( "fieldset.contact_chooser." + prefix + " span.label" ).removeClass( 'selected' )
    $( 'div.' + prefix + '_view' ).removeClass( 'selected' )
    $( '#' + prefix + '_label_' + num ).addClass( 'selected' )
    $( '#' + prefix + '_view_' + num ).addClass( 'selected' )
}
