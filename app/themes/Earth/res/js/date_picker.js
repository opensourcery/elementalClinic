var DEBUG = false           // 'true' to see the actual date control
var ANIMATION_SPEED = null  // "slow", "fast", "null", or milliseconds
var PAGE_PADDING = 5        // number of pixels to pad calendar when it touches the edge of the screen
var PARTIAL_MANUAL_ENTRY_MAX_YEARS_IN_FUTURE = 5 // number of years in future before a year less than 100 is taken to be last century

var CID // FIXME ew, a global ... this really needs to be refactored out

var DatePickers = new Array() // holds all the date pickers

// key codes
var KEY_ENTER = 13
var KEY_TAB = 9
var KEY_SLASH = 47
var KEY_DELETE = 8
var KEY_LEFT = 37
var KEY_UP = 38
var KEY_RIGHT = 39
var KEY_DOWN = 40

// constants
var MONTH_NAMES = [ 0, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' ]
// TODO a clever algorithm could replace this
var DATE_NAMES = [ 0, '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th', '13th', '14th', '15th', '16th', '17th', '18th', '19th', '20th', '21st', '22nd', '23rd', '24th', '25th', '26th', '27th', '28th', '29th', '30th', '31st' ]

var MONTH_NAMES_ABBR = new Array( '0' )
for( var i = 1; i < MONTH_NAMES.length; i++ ) { MONTH_NAMES_ABBR[ i ] = MONTH_NAMES[ i ].substring( 0, 3 ) }
var TODAY = new Date()
TODAY.Y = TODAY.getFullYear()
TODAY.M = TODAY.getMonth() + 1
TODAY.D = TODAY.getDate()

var MIN_YEAR = TODAY.getYear() + 1900 - 125
var MAX_YEAR = TODAY.getYear() + 1900 + 10

var CONTROL_NAMES = new Array()
    CONTROL_NAMES[ 'm' ] = 'month'
    CONTROL_NAMES[ 'd' ] = 'date'
    CONTROL_NAMES[ 'y' ] = 'year'

// jquery init
$( document ).ready( function() {
    $( 'input.date_picker' ).each( function() {
        var dp = new DatePicker( $( this ))
        dp.attach()
        DatePickers[ dp.id ] = dp
    })

    // global key-bindings
    $( document ).keypress( function( e ) {
        // bind ESC
        if( e.which == 27 ) hide_all_calendars()
    });
})

// date control object {{{
function DatePicker( date_picker ) {
    var self = this

    self.input  = date_picker
    self.id     = $( self.input ).attr( 'id' )
    self.manual_entry_problems = new Array()

    /* set_date_from_input
     * sets the Y, M, D properties, either from the associated input element, or today
     */
    DatePicker.prototype.set_date_from_input = function() {
        var self = this

        var current = self.input.attr( 'value' )
        if( current && /\d{4}-\d{1,2}-\d{1,2}/.test( current )) {
            current = current.split( '-' )

            var y = current[ 0 ] || 0
            var m = current[ 1 ] || 0
            var d = current[ 2 ] || 0

            if( /\D/.test( y )) y = TODAY.getFullYear()
            if( /\D/.test( m )) m = TODAY.getMonth() + 1
            if( /\D/.test( d )) d = TODAY.getDate()

            self.Y = y * 1
            self.M = m * 1
            self.D = d * 1
        }
        else if( current ) {
            self.Y = TODAY.getFullYear()
            self.M = TODAY.getMonth() + 1 // zero-based dates are the work of the devil
            self.D = TODAY.getDate()
        }
        else {
            self.Y = 0
            self.M = 0
            self.D = 0
        }
        self.calendar_Y = self.Y || TODAY.Y
        self.calendar_M = self.M || TODAY.M
        self.calendar_D = self.D || TODAY.D

        self.current_control( null )
    }

    /* attach
     * replaces input control with date picker trigger
     */
    DatePicker.prototype.attach = function() {
        var self = this

        var trigger_id = 'date_picker_trigger_'+ self.id
        var button_id = 'date_picker_button_'+ self.id
        var controls_id = 'date_picker_controls_'+ self.id
        $( '#'+ self.id )
            .after( ''
                + '<a class="date_picker_trigger" id="'+ trigger_id +'"><a/>'
                + '<button type="button" class="date_picker_button" id="'+ button_id +'"></button>'
                + '<span class="date_picker_controls" id="'+ controls_id +'">'
                    + '<input type="text" size="3" maxlength="2" value="'+ self.M +'" id="date_picker_control_m_'+ self.id +'" />'
                    + '/'
                    + '<input type="text" size="3" maxlength="2" value="'+ self.D +'" id="date_picker_control_d_'+ self.id +'" />'
                    + '/'
                    + '<input type="text" size="4" maxlength="4" value="'+ self.Y +'" id="date_picker_control_y_'+ self.id +'" />'
                + '</span>'
            )
            .addClass( 'with_trigger' )
        self.controls = $( '#'+ controls_id )
        self.controls.hide()

        self.month_control()
            .keypress( function( e ) { self.capture_manual_entry( e, 'm' ) })
            .click( function( e ) { self.update_from_manual_controls( false, 'm' ) })
        self.date_control()
            .keypress( function( e ) { self.capture_manual_entry( e, 'd' ) })
            .click( function( e ) { self.update_from_manual_controls( false, 'd' ) })
        self.year_control()
            .keypress( function( e ) { self.capture_manual_entry( e, 'y' ) })
            .click( function( e ) { self.update_from_manual_controls( false, 'y' ) })

        self.trigger = $( '#'+ trigger_id )
        self.trigger.click( function() { self.toggle_calendar() })

        self.trigger_button = $( '#'+ button_id )
        self.trigger_button.focus( function() { self.toggle_calendar() })

        self.set_date_from_input()
        self.update_trigger()

        if( DEBUG ) $( '#'+ self.id ).addClass( 'debug' )
    }

    /* update_trigger
     * update the trigger text with a reader-friendly version of the current date
     */
    DatePicker.prototype.update_trigger = function() {
        var self = this
        self.trigger.text( format_date( self.Y, self.M, self.D ))
    }

    /* control_type_API_check
     * returns the previous manual control, assuming MM/DD/YY order and format
     */
    DatePicker.prototype.control_type_API_check = function( control_type, source ) {
        var self = this
        if( ! control_type ) return false
        if(( control_type != 'd' ) && ( control_type != 'm' ) && ( control_type != 'y' )) {
            alert( 'API violation in '+ source +'(): '+ control_type )
            return false
        }
    }

    /* manual entry controls
     */
    DatePicker.prototype.month_control = function() {
        var self = this
        return $( '#date_picker_control_m_'+ self.id )
    }
    DatePicker.prototype.date_control = function() {
        var self = this
        return $( '#date_picker_control_d_'+ self.id )
    }
    DatePicker.prototype.year_control = function() {
        var self = this
        return $( '#date_picker_control_y_'+ self.id )
    }
    // control_type must be 'd' or 'm' or 'y'
    DatePicker.prototype.x_control = function( control_type ) {
        var self = this
        self.control_type_API_check( control_type, 'x_control' )
        return $( '#date_picker_control_'+ control_type +'_'+ self.id )
    }

    /* next_control_type
     * returns the next manual control type, assuming MM/DD/YY order and format
     */
    DatePicker.prototype.next_control_type = function( control_type ) {
        var self = this
        self.control_type_API_check( control_type, 'next_control_type' )
        if( control_type == 'm' ) return 'd'
        if( control_type == 'd' ) return 'y'
        if( control_type == 'y' ) return false
    }

    /* goto_next_control
     * returns the next manual control, assuming MM/DD/YY order and format
     */
    DatePicker.prototype.goto_next_control = function( control_type ) {
        var self = this
        var next_control_type = self.next_control_type( control_type )
        self.x_control( self.next_control_type( control_type )).focus().select()
        self.current_control( next_control_type )
        return self.current_control()
    }

    /* previous_control_type
     * returns the previous manual control type, assuming MM/DD/YY order and format
     */
    DatePicker.prototype.previous_control_type = function( control_type ) {
        var self = this
        self.control_type_API_check( control_type, 'previous_control_type' )
        if( control_type == 'm' ) return false
        if( control_type == 'd' ) return 'm'
        if( control_type == 'y' ) return 'd'
    }

    /* goto_previous_control
     * returns the previous manual control, assuming MM/DD/YY order and format
     */
    DatePicker.prototype.goto_previous_control = function( control_type ) {
        var self = this
        var previous_control_type = self.previous_control_type( control_type )
        self.x_control( self.previous_control_type( control_type )).focus().select()
        self.current_control( previous_control_type )
        return self.current_control()
    }

    /* update_manual_controls
     * updates the manual controls
     */
    DatePicker.prototype.update_manual_controls = function() {
        var self = this

        if( ! self.has_problems( 'm' )) {
            self.month_control().val( self.calendar_M || TODAY.M )
                .removeClass( 'current' )
                .attr( 'maxlength', 2 )
        }
        if( ! self.has_problems( 'd' )) {
            self.date_control().val( self.calendar_D || TODAY.D )
                .removeClass( 'current' )
                .attr( 'maxlength', 2 )
        }
        self.year_control().val( self.calendar_Y || TODAY.Y )
            .removeClass( 'current' )

        if(( self.current_control() != 'm' ) && ! self.has_problems( 'm' )) { // facade the month
            self.month_control()
                .attr( 'maxlength', 4 )
                .val( MONTH_NAMES_ABBR[ self.calendar_M || TODAY.M ])
        }
        if(( self.current_control() != 'd' ) && ! self.has_problems( 'd' )) { // facade the day
            self.date_control()
                .attr( 'maxlength', 4 )
                .val( DATE_NAMES[ self.calendar_D || TODAY.D ])
        }
        if( self.current_control() ) {
            self.x_control( self.current_control() )
                .addClass( 'current' )
                .focus()
                .select()
        }
    }

    /* capture_manual_entry
     * update the calendar, trigger, and value from the manual controls
     */
    DatePicker.prototype.capture_manual_entry = function( e, control_type ) {
        var self = this
        // accept integers
        if(( e.which >= 48 ) && ( e.which <= 57 )) {
            return true
        }
        // allow delete
        else if(( e.which == KEY_DELETE ) || ( e.which == KEY_LEFT ) || ( e.which == KEY_UP ) || ( e.which == KEY_RIGHT ) || ( e.which == KEY_DOWN )) {
            return true
        }
        // ignore everything else, except TAB, ENTER, or SLASH
        else if(( e.which != KEY_TAB ) && ( e.which != KEY_ENTER ) && ( e.which != KEY_SLASH )) {
            e.preventDefault()
            return false
        }

        // at this point, the only keystrokes are TAB, ENTER, or SLASH

        if( e.shiftKey ) {
            // if SHIFT is being held, back up, unless we're on the first control,
            // then let the default happen
            var previous = self.previous_control_type( control_type )
            if( previous ) {
                self.goto_previous_control( control_type )
                self.update_from_manual_controls( false )
                e.preventDefault()
            }
            else {
                self.update_from_manual_controls( true )
                if(( e.which == KEY_ENTER ) || self.has_problems() ) e.preventDefault()
            }
        }
        else {
            var next = self.next_control_type( control_type )
            if( next ) {
                self.goto_next_control( control_type )
                self.update_from_manual_controls( false )
                e.preventDefault()
            }
            else {
                // must manually set previous control, since we're not using goto_next_control
                self.previous_control( control_type )
                self.update_from_manual_controls( true )
                self.goto_next_tabbable_control()
                e.preventDefault()
            }
        }
        e.stopPropagation()
        return false
    }

    /* update_from_manual_controls
     * update the calendar, trigger, and value from the manual controls
     * if given a control_type, set that as the current control
     */
    DatePicker.prototype.update_from_manual_controls = function( close_calendar, control_type ) {
        var self = this

        if( control_type ) self.current_control( control_type )
        if( self.validate_manual_entry( self.previous_control() )) {
            if( close_calendar ) {
                set_date( self.id, self.calendar_Y, self.calendar_M, self.calendar_D ) // hides calendar
                self.update_trigger()
            }
            else {
                self.draw_month()
                if( control_type ) self.x_control( control_type ).select()
            }
        }
        else {
            // we want to make sure that controls other than the one(s) with problems
            // are able to update
            self.update_manual_controls()
        }
    }

    /* toggle_calendar
     * hides or shows the calendar
     */
    DatePicker.prototype.toggle_calendar = function() {
        var self = this

        if( self.trigger.hasClass( 'active' )) { // calendar is up
            self.hide_calendar()
        }
        else {
            hide_all_calendars()
            CID = self.id
            self.trigger.addClass( 'active' )
            self.draw_month()
            self.show_manual_controls()
        }
    }

    /* calendar_active
     * strictly speaking, should be calendar.is_active
     */
    DatePicker.prototype.calendar_active = function() {
        var self = this
        return( $( '#date_picker_'+ self.id ).hasClass( 'active' ))
    }

    /* header
     * returns HTML representing calendar header
     */
    DatePicker.prototype.header = function() {
        var self = this

        var year = self.calendar_Y || TODAY.Y
        var month = self.calendar_M || TODAY.M
        var prev = prev_YM( year, month )
        var next = next_YM( year, month )

        // month selector
        var month_options = ''
        for( var i = 1; i < MONTH_NAMES.length; i++ ) {
            selected = ( i == month ) ? ' selected="selected"' : ''
            month_options = month_options + '<option value="'+ i +'"'+ selected +'>'+ MONTH_NAMES[ i ] +'</option>'
        }
        var month_selector = '<p class="month selector">'
            + '<a id="previous_month_trigger_'+ self.id +'" class="previous_month_trigger"><em>&#171;</em>'+ MONTH_NAMES_ABBR[ prev.m ] +'</a>'
            + '<select id="month_selector_'+ self.id +'">' + month_options + '</select>'
            + '<a id="next_month_trigger_'+ self.id +'" class="next_month_trigger">'+ MONTH_NAMES_ABBR[ next.m ] +'<em>&#187;</em></a>'
            + '</p>'

        // year selector
        var year_options = ''
        var min_year = ( year < MIN_YEAR ) ? year : MIN_YEAR
        var max_year = ( year > MAX_YEAR ) ? year : MAX_YEAR
        for( var i = min_year; i <= max_year; i++ ) {
            selected = ( i == year ) ? ' selected="selected"' : ''
            year_options = year_options + '<option'+ selected +'>'+ i +'</option>'
        }
        var year_selector = '<p class="year selector">'
            + '<a id="previous_year_trigger_'+ self.id +'" class="previous_year_trigger"><em>&#171;</em>'+ ( year * 1 - 1 ) +'</a>'
            + '<select id="year_selector_'+ self.id +'">' + year_options + '</select>'
            + '<a id="next_year_trigger_'+ self.id +'" class="next_year_trigger">'+ ( year * 1 + 1 ) +'<em>&#187;</em></a>'
            + '</p>'

        // return header
        return ''
            + '<div class="date_picker_header">'+ month_selector + year_selector +'</div>'
            + '<table>'
            + '    <tr class="days"><th>Su</th><th>Mo</th><th>Tu</th><th>We</th><th>Th</th><th>Fr</th><th>Sa</th></tr>'
    }

    /* footer
     * returns HTML representing calendar footer
     */
    DatePicker.prototype.footer = function() {
        var self = this
        return ''
            + '</table>'
            + '<ul class="date_picker_footer">'
            + '    <li class="date_picker_cancel"><a>Cancel</a></li>'
            + '    <li class="date_picker_delete"><a>Delete date</a></li>'
            + '</ul>'
    }

    /* weeks
     * returns HTML representing calendar weeks
     */
    DatePicker.prototype.weeks = function() {
        var self = this
        var y = self.calendar_Y || TODAY.Y
        var m = self.calendar_M || TODAY.M
        return get_weeks( self.id, y, m )
    }

    /* week_count
     * returns integer representing number of sunday-to-saturday weeks in month
     */
    DatePicker.prototype.week_count = function() {
        var self = this
        var first_day = new Date( self.calendar_Y, self.calendar_M - 1, 1 ).getDay()
        return Math.ceil(( days_in_month( self.calendar_Y, self.calendar_M ) + first_day ) / 7 )
    }

    /* draw_month
     * sets month and year, then draws it
     */
    DatePicker.prototype.draw_month = function( y, m ) {
        var self = this
        if( y ) self.calendar_Y = y
        if( m ) self.calendar_M = m

        /* FIXME this works, but really shouldn't be necessary
         * the calendar properties should already be set here
         * this only manifest itself when the date is not set, visible by the week_count() calculation being off
         * the manual date controls and the calendar_X properties should be synched, always
         * which means they should probably be methods, instead
         */
        self.calendar_Y = self.calendar_Y || TODAY.Y
        self.calendar_M = self.calendar_M || TODAY.M
        self.calendar_D = self.calendar_D || TODAY.D

        var header  = self.header()
        var weeks   = self.weeks()
        var footer  = self.footer()
        var content = '<div class="content">'+ header + weeks + footer +'</div>'

        if( ! self.calendar_active() ) { // create a new calendar and position it
            $( 'body' ).append( '<div class="date_picker" id="date_picker_'+ self.id +'" style="display:none;">'+ content +'</div>' )

            var position = calendar_position( self.id )
            $( '#date_picker_'+ self.id )
                .css( 'left', position.x1 )
                .css( 'top', position.y2 )
                .addClass( 'active' )
                .show( ANIMATION_SPEED )
        }
        else { // otherwise just replace the content of the current calendar
            $( '#date_picker_'+ self.id )
                .empty()
                .append( content )
        }
        // add the correct class for the shadow, first removing the old one (the lazy way)
        $( '#date_picker_'+ self.id )
            .removeClass( 'week_count4' )
            .removeClass( 'week_count5' )
            .removeClass( 'week_count6' )
            .addClass( 'week_count'+ self.week_count() )

        self.resolve_manual_entry_problems()
        self.update_manual_controls()
        // scroll the calendar into view, if necessary
        $( '#date_picker_'+ self.id ).each( function() {
            this.scrollIntoView()
        })
        self.attach_events()
    }

    /* attach_events
     */
    DatePicker.prototype.attach_events = function() {
        var self = this

        // month & year selectors
        var month_id = '#month_selector_'+ self.id
        var year_id = '#year_selector_'+ self.id
        $( month_id ).change( function() { 
            var month = $( month_id ).attr( 'value' )
            var year = $( year_id ).attr( 'value' )
            self.draw_month( year, month )
        })
        $( year_id ).change( function() { 
            var month = $( month_id ).attr( 'value' )
            var year = $( year_id ).attr( 'value' )
            self.draw_month( year, month )
        })

        // previous & next month
        var prev = prev_YM( self.calendar_Y, self.calendar_M )
        var next = next_YM( self.calendar_Y, self.calendar_M )
        $( '#previous_month_trigger_'+ self.id ).click( function() { self.draw_month( prev.y, prev.m ) })
        $( '#next_month_trigger_'+ self.id ).click( function() { self.draw_month( next.y, next.m ) })

        // previous & next year
        $( '#previous_year_trigger_'+ self.id ).click( function() { self.draw_month(( self.calendar_Y - 1 ), self.calendar_M ) })
        $( '#next_year_trigger_'+ self.id ).click( function() { self.draw_month(( self.calendar_Y + 1 ), self.calendar_M ) })

        // cancel & delete
        $( '#date_picker_'+ self.id +' .date_picker_cancel a' ).click( function() { self.hide_calendar() })
        $( '#date_picker_'+ self.id +' .date_picker_delete a' ).click( function() {
            set_date( self.id )
            self.calendar_Y = TODAY.Y
            self.calendar_M = TODAY.M
            self.calendar_D = TODAY.D
        })
    }

    /* hide_calendar
     */
    DatePicker.prototype.hide_calendar = function( y, m ) {
        var self = this

        self.hide_manual_controls()
        // FIXME this should be an object method
        $( '#date_picker_'+ self.id )
            .hide( ANIMATION_SPEED )
            .remove()
        self.trigger.removeClass( 'active' )
    }

    /* show_manual_controls
     * shows the manual-entry controls
     */
    DatePicker.prototype.show_manual_controls = function( y, m ) {
        var self = this
        if( y ) self.calendar_Y = y
        if( m ) self.calendar_M = m

        self.current_control( 'm' ) // FIXME this should be generalized, using next_control_type()

        self.trigger.hide()
        self.trigger_button.hide()
        self.update_manual_controls()
        self.controls.show()
        self.month_control().focus().select()
    }

    /* hide_manual_controls
     * hides the manual-entry controls
     */
    DatePicker.prototype.hide_manual_controls = function( y, m ) {
        var self = this
        if( y ) self.calendar_Y = y
        if( m ) self.calendar_M = m
        hide_manual_controls( self.id )
    }

    // previous control
    DatePicker.prototype.previous_control = function( control_type ) {
        var self = this
        if( control_type ) {
            self._previous_control = control_type
        }
        return self._previous_control
    }

    // current control
    DatePicker.prototype.current_control = function( control_type ) {
        var self = this
        if( control_type ) {
            self._previous_control = self._current_control
            self._current_control = control_type
        }
        return self._current_control
    }

    /* validate_manual_entry
     * sanity check date, month, and year values
     * highlight those values that are out-of-bounds'
     * returns true if everything is ok, false if there are problems
     * ' * 1' everywhere to eat leading zeroes
     */
    DatePicker.prototype.validate_manual_entry = function( control_type ) {
        var self = this

        if( control_type == 'm' ) {
            var value = self.month_control().val() * 1
            if( value > 12 ) {
                self.add_problem( control_type )
            }
            else {
                self.remove_problem( control_type )
                self.calendar_M = value
            }
        }
        if( control_type == 'd' ) {
            var value = self.date_control().val() * 1
            if( value > days_in_month( self.calendar_Y, self.calendar_M )) {
                self.add_problem( control_type )
            }
            else {
                self.remove_problem( control_type )
                self.calendar_D = value
            }
        }
        if( control_type == 'y' ) self.calendar_Y = correct_manual_year_entry( self.year_control().val() )
        return ! self.has_problems()
    }

    /* add_problem
     * adds the "problem" class to a control
     */
    DatePicker.prototype.add_problem = function( control_type ) {
        var self = this
        self.x_control( control_type ).addClass( 'problem' )
        self.manual_entry_problems[ control_type ] = true
        self.update_problem_message()
    }

    /* remove_problem
     * removes the "problem" class from a control
     */
    DatePicker.prototype.remove_problem = function( control_type ) {
        var self = this
        self.x_control( control_type ).removeClass( 'problem' )
        self.manual_entry_problems[ control_type ] = false
        self.update_problem_message()
    }

    /* has_problems
     * returns "true" if there are problems with any manual entry fields
     * if "control_type" is provided, returns "true" only if there are problems
     * with that control
     */
    DatePicker.prototype.has_problems = function( control_type ) {
        var self = this
        if( control_type ) {
            return self.manual_entry_problems[ control_type ]
        }
        else {
            for( control_type in self.manual_entry_problems ) {
                if( self.manual_entry_problems[ control_type ]) return true
            }
        }
        return false
    }

    /* resolve_manual_entry_problems
     * this is useful when updating from a calendar affordance, rather than
     * a manual entry control
     */
    DatePicker.prototype.resolve_manual_entry_problems = function() {
        var self = this

        for( control_type in self.manual_entry_problems ) {
            self.remove_problem( control_type )
        }
    }

    /* update_problem_message
     * hides message if there are no problems
     * displays message if there are problems, making sure that the problems are listed
     */
    DatePicker.prototype.update_problem_message = function() {
        var self = this

        if( ! self.has_problems() ) {
            $( '#date_picker_'+ self.id ).removeClass( 'has_problems' )
            $( '#date_picker_'+ self.id +' p.date_picker_problems' ).remove()
        }
        else {
            var invalid_what = ''
            var invalid_count = 0
            for( control in self.manual_entry_problems ) {
                if( self.manual_entry_problems[ control ]) {
                    invalid_count++
                    if( invalid_count > 1 ) invalid_what += ' and '
                    invalid_what += ' '+ CONTROL_NAMES[ control ]
                }
            }

            if( $( '#date_picker_'+ self.id ).hasClass( 'has_problems' )) {
                $( '#date_picker_'+ self.id +' p.date_picker_problems' ).text( 'Invalid'+ invalid_what )
                return false
            }
            else {
                $( '#date_picker_'+ self.id ).addClass( 'has_problems' )
                $( '#date_picker_'+ self.id +' div.content' ).prepend( '<p class="date_picker_problems">Invalid'+ invalid_what +'</p>' )
            }
        }
    }

    /* goto_next_tabbable_control
     * finds the next control and focuses it
     * this is necessary because the calendar is constructed at the end of the HTML
     * document, out of the natural tab order
     */
    DatePicker.prototype.goto_next_tabbable_control = function() {
        var self = this

        // go through all input controls and find ourselves
        var controls = new Array()
        var i = 0
        var self_index = 0
        $( ':input' ).each( function( i ) {
            var id = $( this ).attr( 'id' )
            if( ! /^date_picker/.test( id )) {
                controls.push( id )
                if( id == self.id ) self_index = i
                i++
            }
        })
        var next_control = controls[ self_index + 1 ]
        
        // if the next control is a date picker, we need special behavior
        if( DatePickers[ next_control ]) {
            $( '#date_picker_button_'+ next_control ).focus()
        }
        else {
            $( '#'+ next_control ).focus()
        }
    }

}
// }}}

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * everything below should be subroutines, not jquery triggers
 */
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function hide_all_calendars() {
    for( id in DatePickers ) {
        DatePickers[ id ].hide_calendar()
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function hide_manual_controls( id ) {
    var dp = DatePickers[ id ]
    dp.controls.hide()
    dp.trigger.show()
    dp.trigger_button.show()

    // FIXME there has to be a better way or place to do this
    dp.calendar_M = dp.M
    dp.calendar_D = dp.D
    dp.calendar_Y = dp.Y
    dp.update_manual_controls()
}

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * example return data structure for april 2004
 * return [[0,0,0,0,1,2,3],[4,5,6,7,8,9,10],[11,12,13,14,15,16,17],[18,19,20,21,22,23,24],[25,26,27,28,29,30]]
 */
function get_weeks( id, year, month) {
    var dp = DatePickers[ id ]

    var WEEKS = ''
    var days = get_days( year, month )

    for( var weeknum = 0; weeknum < days.length; weeknum++ ) {
        WEEKS += '<tr>'
        for( var day = 0; day < days[ weeknum ].length; day++ ) {
            if( days[ weeknum ][ day ] == 0 ) {
                WEEKS += '<td class="blank"></td> '
            }
            else {
                var classes = get_cell_classes( dp, year, month, days[ weeknum ][ day ], day )
                var clickme = get_onclick( dp.id, year, month, days[ weeknum ][ day ] )
                WEEKS += '<td class="this_month '+ classes +'"><a href="#"'+ clickme + '>'

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
        for( var i = 0; i < the_first; i++ ) {
            days[ i ] = 0 
        }

        for( var i = 1; i < ( 37 ); i++ ) {
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
        for( var i = 1; i <= days.length; i++ ) {
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
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function get_cell_classes( dp, year, month, date, day_position ) {
        var classes = ''
        if( year == dp.Y && month == dp.M && date == dp.D ) {
            classes = classes + ' current'
        }
        if( year == TODAY.getFullYear() && month == ( TODAY.getMonth() + 1 ) && date == TODAY.getDate() ) {
            classes = classes + ' today'
        }
        if(( day_position == 0 ) || ( day_position == 6 )) {
            classes = classes + ' weekend'
        }
        return classes
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function get_onclick( id, year, month, date ) {
    return 'onclick="return set_date( \''+ id +'\','+ year +','+ month +','+ date +' )"'
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function set_date( id, year, month, date ) {
    var dp = DatePickers[ id ]

    ! year
        ? dp.input.attr( 'value', '' )
        : dp.input.attr( 'value', year +'-'+ month  +'-'+ date )

    dp.Y = year || null
    dp.M = month || null
    dp.D = date || null

    dp.update_trigger( id )
    dp.set_date_from_input() // round-trip.  also, helps when date is deleted
    dp.hide_calendar()
    return false
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function calendar_position( cid ) {
    var pos = new Object

    var control = $( '#date_picker_trigger_'+ cid )
    pos.x1 = control.offset().left
    pos.y1 = control.offset().top

    var calendar = $( '#date_picker_'+ cid )
    var calendar_width = calendar.width()

    pos.x2 = pos.x1 + control.width()
    pos.y2 = pos.y1 + control.height()

    var css_width = new Array( 'border-left-width', 'border-right-width', 'padding-left', 'padding-right' )
    for( var i = 0; i < css_width.length; ++i ) {
        pos.x2 = pos.x2 + control.css( css_width[ i ]).split( 'px' )[ 0 ] * 1
        calendar_width = calendar_width + calendar.css( css_width[ i ]).split( 'px' )[ 0 ] * 1
    }
    
    var css_height = new Array( 'border-top-width', 'border-bottom-width', 'padding-top', 'padding-bottom' )
    for( var i = 0; i < css_height.length; ++i ) {
        pos.y2 = pos.y2 + ( control.css( css_height[ i ]).split( 'px' )[ 0 ] * 1 )
    }

    var x_overlap = ( pos.x1 + calendar_width ) - $( 'body' ).width()
    if( x_overlap > 0 ) {
        pos.x1 = pos.x1 - x_overlap - PAGE_PADDING
        pos.x2 = pos.x2 - x_overlap - PAGE_PADDING
    }

    return pos
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // expects year, month, date as actual numbers that correspond to real
        // dates.  BTW, zero-based dates are the work of the devil
        function format_date( year, month, date ) {
            if( ! year || year == 0 ) return 'No date set'
            return MONTH_NAMES[ month ].substring( 0, 3 ) +' '+ date +', '+ year
        }
// Randall says:  zero-based dates are the work of the devil
function get_current_date( current ) {
    if( current && /\d\d\d\d-\d\d-\d\d/.test( current )) {
        current = current.split( '-' )

        var y = current[ 0 ] || 0
        var m = current[ 1 ] || 0
        var d = current[ 2 ] || 0

        m--
        var currentDate = new Date()
        if( /\D/.test( y )) y = currentDate.getFullYear()
        if( /\D/.test( m )) m = currentDate.getMonth()
        if( /\D/.test( d )) d = currentDate.getDate()

        currentDate = new Date( y, m, d )
    }
    else {
        var currentDate = new Date
    }
    return currentDate
}

// UTILITY
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function prev_YM( y, m ) {
    var prev = new Object
    prev.y = y
    prev.m = m
    prev.m--
    if( prev.m == 0 ) {
        prev.m = 12
        prev.y--
    }
    return prev
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function next_YM( y, m ) {
    var next = new Object
    next.y = y
    next.m = m

    next.m++
    if( next.m == 13 ) {
        next.m = 1
        next.y++
    }
    return next
}

/* correct manual year entry
 * if someone enters a 2-digit year, what do we do?
 * this code assumes the year is meant for this century if it is no more than
 * PARTIAL_MANUAL_ENTRY_MAX_YEARS_IN_FUTURE years in the future, otherwise
 * it is taken to mean last century
 */
function correct_manual_year_entry( year ) {
    year *= 1
    if( year < ( TODAY.Y - 2000 + PARTIAL_MANUAL_ENTRY_MAX_YEARS_IN_FUTURE )) {
        year += 2000
    }
    else if( year < 100 ) {
        year += 1900
    }
    return( year )
}

/* days_in_month
 * returns integer representing number days in the month
 */
function days_in_month( year, month ) {
    // day 0 is taken to be the last day of the previous month
    return new Date( year, month, 0 ).getDate()
}

