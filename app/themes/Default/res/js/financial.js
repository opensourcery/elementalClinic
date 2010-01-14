var GLOSS_ON = false
var REQUEST_ACTIVE = false

var TIMER
var DELAY = 500
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function set_working( set_to ) {
    if( set_to && ! set_gloss( true )) return false
    if( set_to ) { // start work
        window.onbeforeunload = highlight_work_in_progress
        document.getElementById( 'work_in_progress' ).style.display = 'block'
        REQUEST_ACTIVE = true
    }
    else { // end work
        if( ! REQUEST_ACTIVE ) return false
        window.onbeforeunload = ''
        document.getElementById( 'work_in_progress' ).className = ''
        document.getElementById( 'work_in_progress' ).style.display = 'none'
        REQUEST_ACTIVE = false
    }
    return true
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function set_gloss( set_to ) {
    if( set_to ) {
        if( GLOSS_ON ) {
            alert( 'hold on, cowboy' )
            return false
        }
        GLOSS_ON = true
    }
    else {
        if( ! GLOSS_ON ) { // return false
            alert( 'erroneous call to "set_gloss()"' )
            return false
        }
        GLOSS_ON = false
        clearTimeout( TIMER )
    }
    return true
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function send_request( uri, response_handler ) {
    if( ! set_working( true )) return false
    try {
        var step = document.getElementById( 'step' )
        var section = document.getElementById( 'section' )
        if( step ) step = ';step='+ step.value
        if( section ) section = ';section='+ section.value
        uri = uri + section + step
        loadXMLDoc( uri, response_handler )
    }
    catch( e ) {
        var msg = ( typeof e == "string" ) ? e : ((e.message) ? e.message : "Unknown Error")
        alert( "Unable to get data:\n" + msg )
        set_working( false )
        return false
    }
    return true
}

/* ********************************************************************
   TRANSACTIONS
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toggle_transaction_error( id ) {
    var transaction = ';transaction_id='+ id
    var uri = '../gateway/financial.cgi?op=payments_2_transaction_toggle_error'+ transaction
    if( ! send_request( uri, process_transaction_error )) return false

    var transaction = document.getElementById( 'transaction_'+ id )
    var was_in_error = transaction.className == 'in_error' ? true : false
    transaction.className = 'updating'
    start_transaction_gloss( id, was_in_error )

    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function process_transaction_error() {
    if( req.readyState != 4) return
    if( req.status == 200 ) {
        // everything's fine
    }
    else {
        alert( "There was a problem retrieving the data:\n" + req.statusText )
    }
    set_working( false )
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function update_transaction_error( id, text ) {
    document.getElementById( id ).innerHTML = text
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function highlight_work_in_progress() {
    document.getElementById( 'work_in_progress' ).className = 'active'
    return 'Please wait until the server has completed working and the pretty spinny thing has gone away.'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function start_transaction_gloss( id, was_in_error ) {
    TIMER = setTimeout( 'end_transaction_gloss( '+ id +','+ was_in_error +' )', DELAY )
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function end_transaction_gloss( id, was_in_error ) {
    document.getElementById( 'transaction_'+ id ).className = was_in_error ? '' : 'in_error'
    set_gloss( false )
}

/* ********************************************************************
   BILLABILITY
   ********************************************************************
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toggle_prognote_billable( id ) {
    var uri = '../gateway/financial.cgi?op=prognote_toggle_billable;prognote_id='+ id
    if( ! send_request( uri, process_transaction_error )) return false
    start_prognote_billable_gloss( id )
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function start_prognote_billable_gloss( id ) {
    var note = document.getElementById( 'note_'+ id )
    var class = note.className
    TIMER = setTimeout( 'end_prognote_billable_gloss( '+ id +',"'+ class +'" )', DELAY )
    note.className = 'updating'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function end_prognote_billable_gloss( id, class ) {
    var note = document.getElementById( 'note_'+ id )
    note.className = ( class.match( /unbillable/ ))
        ? class.replace( /unbillable/, 'billable' )
        : class.replace( /billable/, 'unbillable' )
    set_gloss( false )
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toggle_prognote_manual( id ) {
    var uri = '../gateway/financial.cgi?op=prognote_toggle_manual;prognote_id='+ id
    if( ! send_request( uri, process_transaction_error )) return false
    start_prognote_manual_gloss( id )
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function start_prognote_manual_gloss( id ) {
    var note = document.getElementById( 'note_'+ id )
    var class = note.className
    TIMER = setTimeout( 'end_prognote_manual_gloss( '+ id +',"'+ class +'" )', DELAY )
    note.className = 'updating'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function end_prognote_manual_gloss( id, class ) {
    var note = document.getElementById( 'note_'+ id )
    note.className = ( class.match( /bill_manually/ ))
        ? class.replace( /bill_manually/, 'bill_emc' )
        : class.replace( /bill_emc/, 'bill_manually' )
    set_gloss( false )
}

/* ********************************************************************
   BOUNCING
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function bounce_prognote( id, rolodex_id ) {
    if( document.getElementById( 'note_'+ id ).className.match( /bounced/ )) { return false }
    var insurer = rolodex_id ? ';rolodex_id='+ rolodex_id : ''
    var uri = '../gateway/financial.cgi?op=prognote_bounce;prognote_id='+ id + insurer
    if( ! send_request( uri, process_transaction_error )) return false

    start_prognote_bounce_gloss( id )
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function start_prognote_bounce_gloss( id, class ) {
    var note = document.getElementById( 'note_'+ id )
    var class = note.className
    TIMER = setTimeout( 'end_prognote_bounce_gloss( '+ id +',"'+ class +'" )', DELAY )
    note.className = 'updating'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function end_prognote_bounce_gloss( id, class ) {
    var note = document.getElementById( 'note_'+ id )
    note.className = class +' bounced'
    set_gloss( false )
}


/* ********************************************************************
   VALIDITY
   ********************************************************************
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function toggle_prognote_validity( id, validation_prognote_id ) {
    var note = document.getElementById( 'note_'+ id )
    var current_validity = ';current_validity='+ ( note.className.match( /unpassed/ ) ? 0 : 1 )
    var uri = '../gateway/financial.cgi?op=prognote_toggle_validity;validation_prognote_id='+ validation_prognote_id + current_validity
    if( ! send_request( uri, process_transaction_error )) return false

    start_prognote_validity_gloss( id )
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function start_prognote_validity_gloss( id ) {
    var note = document.getElementById( 'note_'+ id )
    var class = note.className
    TIMER = setTimeout( 'end_prognote_validity_gloss( '+ id +',"'+ class +'" )', DELAY )
    note.className = 'updating'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function end_prognote_validity_gloss( id, class ) {
    var note = document.getElementById( 'note_'+ id )
    note.className = ( class.match( /unpassed/ ))
        ? class.replace( /unpassed/, 'passed' )
        : class.replace( /passed/, 'unpassed' )
    set_gloss( false )
}

/* ********************************************************************
   get prognotes
   ********************************************************************
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function load_prognotes( validation_set_id, rolodex_id ) {
    var insurer = rolodex_id ? ';rolodex_id='+ rolodex_id : ''
    var uri = '/financial.cgi?op=billing_load_prognotes;validation_set_id='+ validation_set_id + insurer
    if( ! send_request( uri, process_load_prognotes  )) return false

    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function process_load_prognotes() {
    if( req.readyState != 4) return
    if( req.status == 200 ) {
        document.getElementById( 'prognote_list' ).innerHTML = req.responseText
    }
    else {
        alert( "There was a problem retrieving the data:\n" + req.statusText )
    }
    set_gloss( false )
    set_working( false )
}

/* ********************************************************************
   load results
   ********************************************************************
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function load_results( validation_set_id, result_set_id, pass, rolodex_id ) {
    var result_set_id = ';result_set_id='+ result_set_id
    var pass = pass ? ';pass='+ pass : ''
    var insurer = rolodex_id ? ';rolodex_id='+ rolodex_id : ''
    var uri = '/financial.cgi?op=billing_load_results;validation_set_id='+ validation_set_id + result_set_id + pass + insurer
    if( ! send_request( uri, process_load_results  )) return false

    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function process_load_results() {
    if( req.readyState != 4 ) return
    if( req.status == 200 ) {
        document.getElementById( 'prognote_list' ).innerHTML = req.responseText
    }
    else {
        alert( "There was a problem retrieving the data:\n" + req.statusText )
    }
    set_gloss( false )
    set_working( false )
}
