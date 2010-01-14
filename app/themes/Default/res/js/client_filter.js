/*
function filter_clients( extra, theme ) {
    update_page( '<strong>Getting clients ...</strong>' )

    var ctlf = document.getElementById( 'client_program_list_filter' )
    var clf = document.getElementById( 'client_list_filter' )
    var params = 'op=filter;extra=' + extra
    if( clf ) params += ';client_list_filter=' + clf.value
    if( ctlf ) params += ';client_program_list_filter=' + ctlf.value;
    call_cgi( params, theme )
    return false
}

function search_clients( extra, theme ) {
    update_page( '<strong>Getting clients ...</strong>' )

    var cs   = document.getElementById( 'search' )
    var params = 'op=search;extra=' + extra
    if( cs ) params += ';search=' + cs.value
    call_cgi( params, theme )
    return false
}

function call_cgi( query, theme ) {
    try {
        loadXMLDoc( '../util/' + theme + '/client_filter.cgi?' + query )
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error")
        alert("Unable to get data:\n" + msg)
        return
    }
}
*/
