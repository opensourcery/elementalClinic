/** Inserts body message into note_body when note_header is selected. */
function insert_note_body() {
    var nh = document.getElementById( 'note_header' )
    var nb = document.getElementById( 'note_body' )
    var notefields = nh.options[nh.selectedIndex].text.split(':')
    if ( notefields.length > 1 ) {
        var notebody = notefields[1]
        nb.value = notebody.replace(/^ /,"")
    } else {
        nb.value = ''
    }
}

function ToggleVisible( id ) {
    var current = $( '#message-' + id ).attr( 'class' )
    var change
    if ( current == 'mailmessage_hide' ) {
        change = 'mailmessage_show'
    }
    else {
        change = 'mailmessage_hide'
    }
    $( '#message-' + id ).removeAttr( 'class' )
    $( '#message-' + id ).attr( 'class', change )
}
