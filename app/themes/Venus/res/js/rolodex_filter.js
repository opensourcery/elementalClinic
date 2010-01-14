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

// global flag
var isIE = false;

// global request and XML document objects
var req;

function loadXMLDoc( url ) {
    // native
    if( window.XMLHttpRequest ) {
        req = new XMLHttpRequest();
        req.onreadystatechange = processReqChange;
        req.open( "GET", url, true );
        req.send( null );
    // ie/windows/activex
    }
    else {
        isIE = true;
        req = new ActiveXObject( "Microsoft.XMLHTTP" );
        if( req ) {
            req.onreadystatechange = processReqChange;
            req.open( "GET", url, true );
            req.send();
        }
    }
}

function processReqChange() {
    if( req.readyState == 4 ) { // only if "OK"
        if( req.status == 200 ) {
            update_page( req.responseText )
         }
         else {
            alert( "There was a problem retrieving the data:\n" + req.statusText );
         }
    }
}

