// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function update_page( name, text ) {
    document.getElementById( name + '_html' ).innerHTML = text
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function reset_manual( name ) {
    
    document.getElementById( name + '_keypressed').value = 0;
    document.getElementById( name + '_manual').value = '';
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function get_diag_codes( name ) {
    
    var codes = document.getElementById( name );
    var manual = document.getElementById( name + '_manual');
    
    var pattern = new RegExp(manual.value, "i"); // ignore case

    var select_html = '<select name=' + name + ' id=' + name + " onchange=reset_manual('" + name + "')>";

    // always keep the 0th element in ('000.00 No Data Available')
    select_html += "<option value='" + codes.options[0].value + "' >" + codes.options[0].value + '</option>';

    for ( var i = 1; i < codes.options.length; i++ ) {
        if ( pattern.test(codes.options[i].value) ) {
            select_html += "<option value='" + codes.options[i].value + "' style='display:block' >" + codes.options[i].value + '</option>';
        } else {
            // hide the ones that don't match
            select_html += "<option value='" + codes.options[i].value + "' style='display:none' >" + codes.options[i].value + '</option>';
        }
    }

    select_html += '</select>';
    
    update_page( name, select_html ); 
    
    // reset the keypressed var so that this function can get triggered again
    var keypressed = document.getElementById( name + '_keypressed' );
    keypressed.value = 0;
}
    
