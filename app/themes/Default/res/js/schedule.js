// vim: ts=4 sts=4 sw=4
//global to differentiate id's on the page
var appointment_prefix

function calendar_filter( year, month ) {
    return filter( year, month, 0 )
}

function appointments_filter( date ) {
    return filter( 0, 0, date )
}

function filter( year, month, day, location_id, rolodex_id ) {

    var v = function(id) { return ($('#' + id).val() || '') };
    window.location = '?'
        +'schedule_availability_id=' + v('schedule_availability_id')
        +';location_id='             + v('location_id')
        +';rolodex_id='              + v('rolodex_id')
        +';date='                    + v('view_appointment_date')
        +';client_id='               + v('client_id')
        ;
    return false;
}

// http://simple.elementalclinic.dev/gateway/appointments.cgi
// ?op=save
// schedule_availability_id=1002;appt_time=14.25;client_id=1001;
function add_appointment( data ) {
    prefix = data.prefix;
    schedule = data.schedule_availability_id;
    time = data.appt_time;
    client = data.client_id;

    // set actual data elements
    var set = function(suffix, value) { $('#' + prefix + suffix).val(value) };
    set('schedule_availability_id', schedule);
    set('appt_time', time);
    set('client_id', client);

    $('#' + prefix + 'appointment_time_facade').html(data.appt_time_display);

    appointment_block().show();

    return false;
}

function edit_appointment( script, client_id, appointment_id ) {
    $('#appointment_content').hide();
    $('#appointment_loading').show();
    appointment_block().show();

    var html = $('#appointment_content').html();
    $.get(
        script,
        {
            op: 'appointment_edit',
            client_id: client_id,
            appointment_id: appointment_id
        },
        function(content) {
            $('#appointment_loading').hide();
            $('#appointment_content').show().html(content);
            $('#appointment_content form.cancel input[type=submit]')
                .click(function() {
                    $('#add_appointment, #delete_appointment').hide();
                    $('#appointment_content').html(html);
                    return false;
                });
        }
    );
    return false;
}

// reload the edit_appointment appt_time select box with new appointment times
// pulled from the database for the current schedule_availability_id
// prefix - designation used to differentiate instances of
//          the popup/appointment.html template in the page
//          (view/edit/add)
// script - the cgi script that was called to produce the
//          popup/appointment.html; needed so that we can
//          call the proper controller.
function update_appointment_times( prefix, script ) {
    //needed to update the page with returned html
    appointment_prefix = prefix

    update_appointment_times_update_page( "<p>Updating appointment times...</p>" )

    try {
        loadXMLDoc(
            script
            + '?op=request_times;schedule_availability_id='
            + $('#' + prefix + 'schedule_availability_id').val(),
            update_appointment_times_req
        )
    }
    catch( e ) {
        var msg = (typeof e == "string") ? e : ((e.message) ? e.message : "Unknown Error")
        alert("Unable to get data:\n" + msg)
        return
    }

   return true; 
}

function update_appointment_times_req() {
    if( req.readyState != 4) return
    req.status == 200
        ? update_appointment_times_update_page( req.responseText )
        : alert( "There was a problem retrieving the data:\n" + req.statusText )
}

function update_appointment_times_update_page( content ) {
    $('#' + appointment_prefix + 'appointment_times').html(content);
}

function delete_appointment( prefix, event, appointment_id, who, time, doctor, location ) {
    $('#' + prefix + 'appointment_id').val(appointment_id);
    $('#delete_who').text(who);
    $('#delete_time').text(time);
    $('#delete_doctor').text(doctor);
    $('#delete_location').text(location);
    $('#delete_appointment').show();
    return false;
}

function appointment_block() {
    return $('#add_appointment')
}

$(function() {
    // these will only be here if quick_schedule_availability is false
    $(
        '.filters select#location_id, '+
        '.filters select#rolodex_id, '+
        '.filters select#schedule_availability_id'
    ).change(function() { return filter() });

    $('form.cancel input[type=submit]').click(function() {
        $('#add_appointment, #delete_appointment').hide();
        return false;
    });

    var add_click_day;
    var click_day;
    click_day = function(url, opt) {
        url || (url = $(this).attr('href'));
        opt || (opt = {})
        $.extend(opt, { op: 'calendar' });
        var $select = $('.filters select');
        // qsa = 0
        if ($select.length > 0) {
            opt.rolodex_id  = $('#rolodex_id').val();
            opt.location_id = $('#location_id').val();
        }
        $.get(
            url, opt,
            function(data) { $('#calendar').html(data); add_click_day(); }
        );
        return false;
    };
    add_click_day = function() {
        $('#calendar th a').click(function() { return click_day.apply(this) });
    };

    click_day('/schedule.cgi', {
        'date':      $('#current_date').val() || '',
        'client_id': $('#client_id').val()    || '',
    });
});
