function filter_roles( role_name, client_id, staff_id, theme ) {
    var rn = ';role_name=' + role_name
    var ci = ';client_id=' + client_id
    var si = ';staff_id=' + staff_id
    try {
        update_page( '<p>Searching ...</p>' )
        var radio = document.getElementById
        loadXMLDoc( '/rolodex_filter_roles.cgi?op=filter_roles;' + rn + ci + si );
    }
    catch( e ) {
        var msg = ( typeof e == "string" ) ? e : (( e.message ) ? e.message : "Unknown Error");
        alert( "Unable to get data:\n" + msg );
        return;
    }
    return false
}

function update_page( text ) {
    document.getElementById( 'rolodex_entries' ).innerHTML = text
}
