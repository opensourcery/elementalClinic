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
    var selector = document.getElementById( 'client_selector' )
    if( selector.style.display == 'block' ) {
        selector.style.display = 'none'
        document.getElementById( 'client_selector_link' ).className = ''
    }
    else {
        selector.style.display = 'block'
        document.getElementById( 'client_selector_link' ).className = 'active'
        if( ! document.getElementById( 'client_selector_loaded' )) {
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
    document.getElementById( 'clients' ).innerHTML = text
    document.getElementById( 'client_selector_loaded' ).value = 1
}

/* For dynamically resizing elements with scrollbars. */
function live_resize() {
    if( typeof resize_percentage == 'undefined' ||
        ! resize_percentage ) { return false }
        var e = document.getElementById( resize_element )
        if( ! e ) { return false }
        e.style.height = Math.round( window.innerHeight * (resize_percentage/100) ) +"px"
}
window.onresize = live_resize
window.onload = live_resize

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
function help_toggle() {
    var link = document.getElementById( 'help_link' )
    if( link.className ) {
        link.className = ''
        document.getElementById( 'help_main' ).style.display = 'none'
    }
    else {
        link.className = 'active'
        document.getElementById( 'help_main' ).style.display = 'block'
    }
    return false
}

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
function show_help( helper_name ) {
    var selector = document.getElementById( 'client_selector' )

    document.getElementById( 'help_body' ).style.display = 'none'
    document.getElementById( 'help_loading' ).style.display = 'block'

    var menu = document.getElementById( 'help_list' )
    if( menu.hasChildNodes ) {
        // reset all styles
        for( var i = 0; i < menu.childNodes.length; i++) {   
            menu.childNodes[ i ].className = ''
        }
    }
    document.getElementById( 'help_' + helper_name ).className = 'active'

    try {
        loadXMLDoc( 'help.cgi?op=helper;name='+ helper_name, process_helper_req )
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error")
        alert( "Unable to get data:\n" + msg )
        return
    }
    return false
}

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
function process_helper_req() {
    if( req.readyState != 4) return
    req.status == 200
        ? update_helper( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
function update_helper( text ) {
    document.getElementById( 'help_body' ).innerHTML = text
    document.getElementById( 'help_loading' ).style.display = 'none'
    document.getElementById( 'help_body' ).style.display = 'block'
}
