$(window).on('load', function(e){
    var hash = location.hash.substr(1);
    if (!hash || hash.length == 0){// empty
        location.href += '#home';
    }
    else{
        var url = location.pathname.substr(1) + '/' + hash.replace('#', '');
        changetab(url, hash);
    }
});

// login selection
$(document).on('change', '#select_login_teams', function(e){
    e.preventDefault();

    if ($(this).val() == 'newteam'){
        // show modal
        //$('#add_team_link').trigger('click'); // Not Working!!
        var url = $('#add_team_link').attr("href");
        $('#modal').load(url + ' .modal-dialog');
        $("#modal").modal();
    }
    else{
        var form = $('#select_team_form');
        var action_url = form.attr('action');
        var data = form.serializeJson();
        
        $('#home_tab').load(action_url, data);
    }
});

$(document).on('submit', '#search_team_form', function(e){
    e.preventDefault();

    var query = $('#search_input').val();
    if (query != ""){
        var action_url = $(this).attr('action');
        $('#modal').load(action_url + '?query=' + query + ' .modal-dialog');
        $("#modal").modal();
    }
});

$(document).on('submit', '#registration_team_form', function(e){
    e.preventDefault();
    
    var form = $(this);
    var data = form.serializeJson();
    var action_url = $(this).attr('action');
    $('#modal').load(action_url + ' .modal-dialog', data);
    $("#modal").modal();
});