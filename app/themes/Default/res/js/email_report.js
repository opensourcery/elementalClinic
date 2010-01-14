function toggle_body( id ) {
    var current = $( id ).attr( 'class' )
    var change
    if ( current == 'email_hide_body' ) {
        change = 'email_show_body '
    }
    else {
        change = 'email_hide_body '
    }
    $( id ).removeAttr( 'class' )
    $( id ).attr( 'class', change )
}
