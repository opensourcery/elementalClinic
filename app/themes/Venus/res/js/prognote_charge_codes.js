function get_codes( theme ) {
    var cid = document.getElementById( 'client_id' )        || ''
    var cc = document.getElementById( 'charge_code_id' )    || ''
    var nd = document.getElementById( 'note_date' )         || ''
    var st = document.getElementById( 'start_time' )        || ''
    var lid = document.getElementById( 'note_location_id' ) || ''
    var wid = document.getElementById( 'writer_id' )        || ''

    update_page( 'Code: <strong>Getting codes ...</strong>' )
    if( cid ) cid = '&client_id=' + cid.value
    if( cc ) cc = '&charge_code_id=' + cc.value
    if( nd ) nd = '&note_date=' + nd.value
    if( st ) st = '&start_time=' + st.value
    if( lid ) lid = '&note_location_id=' + lid.value
    if( wid ) wid = '&writer_id=' + wid.value
    try {
        loadXMLDoc( '/progress_notes_charge_codes.cgi?' + cid + cc + nd + st + lid + wid );
        timer( 'start' )
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error");
        alert("Unable to get data:\n" + msg);
        return;
    }
    return false
}

function update_page( text ) {
    document.getElementById( 'valid_charge_codes' ).innerHTML = text
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
            timer( 'stop' )
            update_page( req.responseText )
         }
         else {
            alert( "There was a problem retrieving the data:\n" + req.statusText );
         }
    }
}

var timestamp = 0
function timer( action ) {
    return false
    var timer = document.getElementById( 'timer' )
    var date = new Date()
    if( action == 'start' ) {
        timestamp = date.getTime()
        timer.innerHTML = ''
    }
    if( action == 'stop' ) {
        timestamp = date.getTime() - timestamp
        timestamp = timestamp / 1000
        timer.innerHTML = '('+ timestamp +'s)'
    }
}
