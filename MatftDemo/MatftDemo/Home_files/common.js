$(function() {
    $( ".datepicker" ).datepicker({
      changeMonth: true,
      changeYear: true,
      yearRange: "1900:2012",
      // You can put more options here.

    });
  });

// for ajax csrf token: https://stackoverflow.com/questions/54835849/django-how-to-send-csrf-token-with-ajax
function getCookie(name) {
  var cookieValue = null;
  if (document.cookie && document.cookie != '') {
      var cookies = document.cookie.split(';');
      for (var i = 0; i < cookies.length; i++) {
          var cookie = jQuery.trim(cookies[i]);
          // Does this cookie string begin with the name we want?
          if (cookie.substring(0, name.length + 1) == (name + '=')) {
              cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
              break;
          }
      }
  }
  return cookieValue;
}
var csrftoken = getCookie('csrftoken');

function csrfSafeMethod(method) {
  // these HTTP methods do not require CSRF protection
  return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
}
$.ajaxSetup({
  crossDomain: false, // obviates need for sameOrigin test
  beforeSend: function(xhr, settings) {
      if (!csrfSafeMethod(settings.type)) {
          xhr.setRequestHeader("X-CSRFToken", csrftoken);
      }
  }
});

// edit by ajax
$(document).ready(function(){// document ready is needed to call ajax!
  $('.form_edit').submit(function(e){
      e.preventDefault();

      var form = $(this);
      var actionUrl = form.attr('action');
      data = form.serialize();

      $.ajax({
          type: "POST",
          url: actionUrl,
          data: data,
          success: function (response) {
              Object.keys(data).forEach(function(key) {
                  $('#id_' + key).val(data[key]);
              });
              location.reload(true);
          }
      });
  });
});

// serialize json for form
$.fn.serializeJson = function(){
  var data = {};
  this.serializeArray().map(function(x){
      data[x.name] = x.value;
  });
  return data;
};

// show modal
$(document).on('click', '.modal_link', function(e){
  e.preventDefault();
  
  var url = $(this).attr("href");
  $('#modal').load(url + ' .modal-dialog');
  $("#modal").modal();
});

// modal back
$(document).on('click', '.modal_back_btn', function(e){
  e.preventDefault();

  var url = $(this).attr("href");
  $('#modal').load(url + ' .modal-dialog');
  $("#modal").modal();
});

// change tab
//hometabから，本当にこの実装で良いか再考
$(window).on('hashchange', function(e){
  var hash = location.hash;

  // load content
  var url = location.pathname.substr(1) + '/' + hash.replace('#', '');
  changetab(url, hash);
});

function changetab(url, hash){
  $(hash + '_tab').load(url);

  // hide all
  var tabcontents = $('.tab-content');
  tabcontents.css('display', 'none');

  // deactivate all
  var tablinks = $('.tab-link');
  tablinks.removeClass("active");

  // activate a given class
  $(hash + '_tab').css('display', 'block');
}