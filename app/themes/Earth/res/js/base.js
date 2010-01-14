/*
 * AJAX basics
 */
var isIE = false;   // global flag
var req;            // global request and XML document objects

function loadXMLDoc( url, processor ) {
    // native
    if( ! processor ) processor = processReqChange
    if( window.XMLHttpRequest ) {
        req = new XMLHttpRequest()
        req.onreadystatechange = processor
        req.open( "GET", url, true )
        req.setRequestHeader( 'REFERER', location.href );
        req.send( null )
    // ie/windows/activex
    }
    else {
        isIE = true
        req = new ActiveXObject( "Microsoft.XMLHTTP" )
        if( req ) {
            req.onreadystatechange = processor
            req.open( "GET", url, true )
            req.send()
        }
    }
}

function processReqChange() {
    if( req.readyState != 4) return
    req.status == 200
        ? update_page( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

/*
 * client selector, on nearly every page
 */
function client_selector( controller ) {
    if( document.getElementById( 'no_client_selector_popup' )) return true

    var selector = document.getElementById( 'client_selector' )
    if( selector.style.display == 'block' ) {
        selector.style.display = 'none'
        document.getElementById( 'client_selector_link' ).className = ''
    }
    else {
        selector.style.display = 'block'
        document.getElementById( 'client_selector_link' ).className = 'active'
        var loaded = document.getElementById( 'client_selector_loaded' )
        if( ! loaded || loaded.value == 0 ) {
            // turn on "loading" message
            document.getElementById( 'client_selector_status' ).style.display = 'block'
            try {
                loadXMLDoc( 'ajax.cgi?op=client_selector;controller='+ controller, process_client_selector_req )
            }
            catch( e ) {
                var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error")
                alert("Unable to get data:\n" + msg)
                return
            }
        }
        else {
            document.getElementById( 'search' ).focus()
        }
    }
    return false
}

function process_client_selector_req() {
    if( req.readyState != 4) return
    req.status == 200
        ? update_client_selector( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

function update_client_selector( text ) {
    document.getElementById( 'client_selector_status' ).style.display = 'none'
    document.getElementById( 'client_selector_body' ).innerHTML = text
    document.getElementById( 'client_selector_loaded' ).value = 1
    document.getElementById( 'search' ).focus()
}

/*
 * client filtering and searching
 */

function filter_clients( extra, theme ) {
    client_filter_update_page( '<strong>Getting clients ...</strong>' )

    var ctlf = document.getElementById( 'client_program_list_filter' )
    var clf = document.getElementById( 'client_list_filter' )
    var params = 'op=filter;extra=' + extra
    if( clf ) params += ';client_list_filter=' + clf.value
    if( ctlf ) params += ';client_program_list_filter=' + ctlf.value;
    call_cgi( params, theme )
    return false
}

function search_clients( extra, theme ) {
    client_filter_update_page( '<strong>Getting clients ...</strong>' )

    var cs   = document.getElementById( 'search' )
    var params = 'op=search;extra=' + extra
    if( cs ) params += ';search=' + cs.value
    call_cgi( params, theme )
    return false
}

function call_cgi( query, theme ) {
    try {
        loadXMLDoc( '/client_filter.cgi?' + query, client_filter_req )
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error")
        alert("Unable to get data:\n" + msg)
        return
    }
}

function client_filter_req( ) {
    if( req.readyState != 4) return
    req.status == 200
        ? client_filter_update_page( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

function client_filter_update_page( text ) {
    document.getElementById( 'client_results_control' ).innerHTML = text
    var select = document.getElementById( 'client_id' )
    if( select ) {

        var options = select.getElementsByTagName( 'option' )
        if( options.length == 1 ) {
            document.getElementById( 'view_client' ).style.display = 'none'
            document.getElementById( 'clientform' ).submit()
        }
    }
}

/*
 * everything below here is jquery-based
 */
$( document ).ready( function() {
    $( ".autofocus" ).focus()
})

