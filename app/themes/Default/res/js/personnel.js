function init_widgets() {
    activate( get_current() )
}

function show_widget( widget_id ) {
    var current = get_current()
    deactivate( current )
    activate( widget_id )
    set_current( widget_id )
}

function get_current() {
    return document.getElementById( 'current_widget' ).value
}

function set_current( widget_id ) {
    document.getElementById( 'current_widget' ).value = widget_id
}

function activate( widget_id ) {
    document.getElementById( 'control_'+ widget_id ).className = 'active'
    document.getElementById( widget_id ).className = 'widget active'
}

function deactivate( widget_id ) {
    if( widget_id ) {
        document.getElementById( 'control_'+ widget_id ).className = 'inactive'
        document.getElementById( widget_id ).className = 'widget inactive'
    }
}

onload = init_widgets
