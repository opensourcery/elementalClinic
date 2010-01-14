// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function draw_month( this_year, this_month ) {
    get_params()
    set_dates()

    if( !this_year ) this_year = CURRENT_Y
    if( !this_month ) this_month = CURRENT_M

    var header  = get_header( this_year, this_month )
    var weeks   = get_weeks( this_year, this_month )
    var footer  = get_footer()

    var caldiv = document.getElementById( 'calendar' )
    caldiv.innerHTML = header + weeks + footer

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function get_header( year, month ) {
        prev = prev_MY( year, month )
        next = next_MY( year, month )

        var month_names = [ 0, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ]

        var HEADER = ''
            + '<table cellpadding="0" cellspacing="0">'
            + '    <tr class="head">'
            + '        <th class="nav"><a href="#" onclick="draw_month('+ prev[0] +','+ prev[1] +'); return false;">&#171;</th>'
            + '        <th class="label" colspan="5">'+ month_names[ month ] +' '+ year +'</th>'
            + '        <th class="nav"><a href="#" onclick="draw_month('+ next[0] +','+ next[1]  +'); return false;">&#187;</th>'
            + '    </tr>'
            + '<tr class="days"><th>S</th><th>M</th><th>T</th><th>W</th><th>T</th><th>F</th><th>S</th></tr>'

//         alert( HEADER )
        return HEADER

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        function prev_MY( y, m ) {
            m--
            if( m == 0 ) {
                m = 12
                y--
            }
            return([ y, m ])
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        function next_MY( y, m ) {
            m++
            if( m == 13 ) {
                m = 1
                y++
            }
            return([ y, m ])
        }
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function get_weeks( year, month) {
        var WEEKS = ''
        var days = get_days( year, month )

        for( var weeknum = 0; weeknum < days.length; weeknum++ ) {
            WEEKS += '<tr>'
            for( var day = 0; day < days[ weeknum ].length; day++ ) {
                if( days[ weeknum ][ day ] == 0 ) {
                    WEEKS += '<td class="blank"></td> '
                }
                else {
                    var style = get_style( this_year, this_month, days[ weeknum ][ day ] )
                    var clickme = get_onclick( this_year, this_month, days[ weeknum ][ day ] )
                    WEEKS += '<td><a href="#"'+ style +' '+ clickme + '>'

                    WEEKS += days[ weeknum ][ day ]
                    WEEKS += '</a></td> '
                }
            }
            WEEKS += "</tr>"
        }
        return WEEKS

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        function get_days( year, month ) {
            var date = new Date( year, month - 1, 1 )

            var the_first = date.getDay()

            var i
            var days = []
            for( i = 0; i < the_first; i++ ) {
                days[ i ] = 0 
            }

            for( i = 1; i < ( 37 ); i++ ) {
                date.setDate( i )
                if( date.getMonth() >= month || i > 31 ) {
                    days[ i + the_first - 1 ] = 0
                }
                else {
                    days[ i + the_first - 1 ] = i
                }
            }

            var one_week = []
            var this_month = []
            var index = 0
            for( i = 1; i <= days.length; i++ ) {
                one_week[ index ] = days[ i - 1 ]
                index = i % 7

                if( index == 0 ) {
                    this_month[ this_month.length ] = one_week
                    one_week = []
                }
            }
            // added to get the weeks where the 31st is a Sunday
            this_month[ this_month.length ] = one_week

            return this_month
//             static data for april 2004
//             return [[0,0,0,0,1,2,3],[4,5,6,7,8,9,10],[11,12,13,14,15,16,17],[18,19,20,21,22,23,24],[25,26,27,28,29,30]]
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        function get_style( year, month, date ) {
            if( year == CURRENT_Y && month == CURRENT_M && date == CURRENT_D ) { return ' class="current"' }
            if( year == TODAY_Y && month == TODAY_M && date == TODAY_D ) { return ' class="today"' }
            return ''
        }

    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function get_footer() {
        var FOOTER = ''
            + '    <tr><td colspan="7"><hr /></td></tr>'
            + '    <tr class="key">'
            + '        <td class="current">x</td><td class="key" colspan="3"> = Selected</td>'
            + '        <td class="today">x</td><td class="key" colspan="2"> = Today</td>'
            + '    </tr>'
            + '</table>'
        return FOOTER
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function get_params() {
        params = window.location.search.split( '?' )[ 1 ].split( ';' )
        for( var i = 0; i < params.length; i++ ) {
            p = params[ i ].split( '=' )
            switch( p[ 0 ]) {
                case 'cid'          : CID           = p[ 1 ]; break
                case 'current_date' : CURRENT_DATE  = p[ 1 ]; break
                case 'date_format'  : DATE_FORMAT   = p[ 1 ]; break
            }
        }
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // sets a bunch of globals; ooh, that's nasty
    function set_dates() {
        var current_date = get_current_date( CURRENT_DATE )
        CURRENT_Y = current_date.getFullYear()
        CURRENT_M = current_date.getMonth() + 1
        CURRENT_D = current_date.getDate()

        var today_date = get_current_date()
        TODAY_Y = today_date.getFullYear()
        TODAY_M = today_date.getMonth() + 1
        TODAY_D = today_date.getDate()
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function get_onclick( year, month, date ) {
    return 'onclick="return set_date( '+ year +','+ month +','+ date +' )"'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function set_date( year, month, date ) {
    var date_control = opener.document.getElementById( CID )
    date_control.value = year +'-'+ month  +'-'+ date

    var facade = opener.document.getElementById( CID +'_facade' )
    update_facade( facade, 0, year, month, date, DATE_FORMAT )
    facade.focus()
    self.close()
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function show_calendar( cid, current_date, date_format ) {
    var calwin = window.open(
        "calendar.cgi?op=popup;cid="+ cid +";current_date="+ current_date + ';date_format=' + date_format,
        "Calendar", 
//         "location=1,"+
        "status=1,width=220,height=300,status=no,resizable=yes,top=100,left=100" );
    return false;
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 9 : tab
// 13 : enter
function alter_date( event ) {
    var MINUTE = 60 * 1000
    var HOUR = MINUTE * 60
    var DAY = HOUR * 24

    var key = event.keyCode
    if( !(( key == 9 ) || ( key == 13 ))) { // tab or enter
        event.preventDefault()
    }

//     var key = event.keyCode
    var elm_facade = event.currentTarget
    var elm_real = document.getElementById( elm_facade.id.split( '_facade' )[ 0 ] )

    if(( key == 38 ) || ( key == 40 )) {
        var currentDate = get_current_date( elm_real.value )

        // "up" keycode is 38, "down" is 40, so this gives us the value to add to 
        // the date.  flipping the sign has widget behave like scrolling up and
        // down through a list, rather than incrementing and decrementing values
        var delta = ( 39 - key )
        var new_date

        if( event.ctrlKey ) { // year
            new_date = new Date( currentDate )
            new_date.setYear( currentDate.getFullYear() + delta )
        }
        else if( event.shiftKey ) { // month
            new_date = new Date

            var newM = currentDate.getMonth()
            newM += delta
            if( newM == -1 ) {
                new_date.setYear( currentDate.getFullYear() - 1 )
                new_date.setMonth( 11 ) // since they're bleeding zero-based
            }
            else if( newM == 13 ) {
                new_date.setYear( currentDate.getFullYear() + 1 )
                new_date.setMonth( 0 ) // since they're bleeding zero-based
            }
            else {
                new_date.setYear( currentDate.getFullYear())
                new_date.setMonth( newM ) // since they're bleeding zero-based
            }
            new_date.setDate( currentDate.getDate() )
        }
        else {
            delta = DAY * delta
            var c = currentDate * 1

            /* adjustment is for daylight savings time.  
               An extra .5 delta is enough to move the 
               date forward, and isn't needed when moving
               the date backwards
            */
            if( delta > 0 ) {
                delta = delta * 1.5;
            }
            new_date = new Date( delta + c )
        }
        update_facade( elm_facade, new_date, 0, 0, 0, date_format )
        elm_real.value = new_date.getFullYear() +'-'+ ( new_date.getMonth() + 1 ) +'-'+ new_date.getDate()
    }
    // 8 and 46 are delete and backspace
    else if(( key == 8 ) || ( key == 46 )) {
        elm_facade.value = ''
        elm_real.value = ''
    }
/*  haven't yet figured out how to get this to use the date_format
    maybe: have date_format as a hidden form field, always pull it dynamically
    from parent window?

    else if(( event.which == 67 ) || ( event.which == 99 )) { // 'C' or 'c'
        event.preventDefault()
        show_calendar( elm_real.id, elm_real.value )
        return false
    }
*/
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function init_facade( element_id, date_format, date_string ) {
    if( !date_string ) { return }
    // the above statement might need to be
    // if( !document.getElementById( element_id ).value ) { return }
    date_string = document.getElementById( element_id ).value;

    var facade = document.getElementById( element_id +'_facade' )
    year = date_string.split( '-' )[ 0 ] * 1
    month = date_string.split( '-' )[ 1 ] * 1
    date = date_string.split( '-' )[ 2 ] * 1

    update_facade( facade, 0, year, month, date, date_format )
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function update_facade( element, date_object, year, month, date, date_format ) {
    var facade_string
    if( date_object ) {
        facade_string = format_date( date_format,
            date_object.getFullYear(),
            date_object.getMonth() + 1,
            date_object.getDate()
        )
    }
    else {
        facade_string = format_date( date_format, year, month, date )
    }
    element.value = facade_string
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function init_static( element_id, date_format, date_string ) {
    if( !date_string ) { return }

    var element = document.getElementById( element_id )
    if( date_string == 'today' ) {
        element.innerHTML = ''
    }
    else {
        year = date_string.split( '-' )[ 0 ] * 1
        month = date_string.split( '-' )[ 1 ] * 1
        date = date_string.split( '-' )[ 2 ] * 1

        date_string = format_date( date_format, year, month, date )
        element.innerHTML = date_string // FIXME
    }
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// expects year, month, date as actual numbers that correspond to real
// dates.  BTW, zero-based dates are the work of the devil
function format_date( format, year, month, date ) {
    var month_names = [ 0, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ]
    if( !format ) {
        format = 'medium'
    }

    var date_string
    if( format == 'medium' ) {
        month = month_names[ month ]
        month = month.substring( 0, 3 )
        date_string = date +' '+ month +' '+ year
    }
    else if( format == 'long' ) {
        month = month_names[ month ]
        date_string = month +' '+ date +', '+ year
    }
    else if( format == 'mdy' ) {
        date_string = month + '/' + date + '/' + year
    }
    else if( format == 'compact_mdy' ) {
        year = year + ''
        year = year.substring( 2, 4 )
        date_string = month +'/'+ date +'/'+ year
    }
    else if( format == 'compact_dmy' ) {
        year = year + ''
        year = year.substring( 2, 4 )
        date_string = date +'/'+ month +'/'+ year
    }
    else { // sql is the default
        date_string = year +'-'+ month +'-'+ date
    }
    return date_string

}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Randall says:  zero-based dates are the work of the devil
function get_current_date( current ) {
    if( current ) {
        current = current.split( '-' )

        var y = current[ 0 ] || 0
        var m = current[ 1 ] || 0
        var d = current[ 2 ] || 0

        m--

        if( /\D/.test( y )) y = currentDate.getFullYear()
        if( /\D/.test( m )) m = currentDate.getMonth()
        if( /\D/.test( d )) d = currentDate.getDate()

        var currentDate = new Date( y, m, d )
    }
    else {
        var currentDate = new Date
    }
    return currentDate
}
