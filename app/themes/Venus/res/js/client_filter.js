function filter_clients( extra, theme ) {
    client_filter_update_page( '<strong>Getting clients ...</strong>' )

    var ctlf = document.getElementById( 'client_program_list_filter' )
    var clf = document.getElementById( 'client_list_filter' )
    var params = 'op=filter;extra=' + extra;
    if( clf ) params += ';client_list_filter=' + clf.value;
    if( ctlf ) params += ';client_program_list_filter=' + ctlf.value; 
    call_cgi( params, theme )
    return false
}

function search_clients( extra, theme ) {
    client_filter_update_page( '<strong>Searching ...</strong>' )

    var cs   = document.getElementById( 'search' )
    var params = 'op=search;extra=' + extra;
    if( cs ) params += ';search=' + cs.value;
    call_cgi( params, theme )
    return false
}

function call_cgi( query, theme ) {
    try {
        loadXMLDoc( '/client_filter.cgi?' + query, process_client_filter_req );
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error");
        alert("Unable to get data:\n" + msg);
        return;
    }
}

function client_filter_update_page( text ) {
    document.getElementById( 'client_results_control' ).innerHTML = text
}

function process_client_filter_req() {
    if( req.readyState != 4) return
    req.status == 200
        ? client_filter_update_page( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

