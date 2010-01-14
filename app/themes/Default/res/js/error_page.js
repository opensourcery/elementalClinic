$(document).ready(function() {
  $("#show-fields").bind( 'click', function() { expand_fields() })
  $("#hide-fields").bind( 'click', function() { collapse_fields() })
  $(".obfuscatable").bind( 'click', function(e) { obfuscate($(e.target)) })
  $(".report_link").each( function() {
    var href = $(this).attr( 'href' )
    var id = $(this).attr('id')
    var name_id = "#" + id + "name";
    var name = $( name_id ).val()
    $(this).removeAttr('href')
    $(this).removeAttr('target')
    $(this).bind( 'click', function(e) { show_report(href, name)})
  })
})

function expand_fields() {
  $("#data-fields").show()
  $("#hide-fields").show()
  $("#show-fields").hide()
}

function collapse_fields() {
  $("#data-fields").hide()
  $("#show-fields").show()
  $("#hide-fields").hide()
}

function obfuscate( target ) {
  var original = target.text()
  obfuscated = original.replace(/[A-Z]/g, 'X')
  obfuscated = obfuscated.replace(/[a-z]/g, 'x')
  obfuscated = obfuscated.replace(/[1-9]/g, '0')
  obfu_replace( original, obfuscated )
  $('#error_form').append("<input class='obfuscate' type='hidden' id='obfuscate' name='obfuscate' value='" + original + "' />")
}

function obfu_replace( original, obfuscated ) {
  $('.obfuscatable:contains("' + original + '")').each( function() {
     var text = $(this).text()
     var match = new RegExp(original, 'gi')
     newtext = text.replace( match, obfuscated )
     $(this).text( newtext )
     if ( text == original ) {
        $(this).removeClass( 'obfuscatable' )
        $(this).addClass( 'obfuscated' )
        $(this).unbind( 'click' )
     }
  })
}

function show_report( url, id ) {
  var obfu = []
  $('.obfuscate').each( function() {
    obfu.push( $(this).val())
  })
  $("#exception-text").load(
    url,
    {
        obfuscate: obfu,
        op: 'retrieve',
        exception: id,
    },
    function() {
        $(".obfuscatable").unbind( 'click' )
        $(".obfuscatable").bind( 'click', function(e) { obfuscate($(e.target)) })
    }
  )
}
