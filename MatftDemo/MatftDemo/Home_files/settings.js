
// main modal click event
$(document).on('click', '.settings_link', function(e){
    e.preventDefault();

    var content = $(this).parent().attr("class");
    var url = $(this).attr("href");
    // GET
    $('#modal').load(url + ' .modal-dialog', function(e){
        if (content == 'basic'){
            //basic_ready(e);
        }
    });
    $("#modal").modal();
    // POST
    //$('#modal').load(settings_url, {action_type: action_type}, '.modal-dialog');
});

// switch save and modify button
$(document).on('click', '.settings_save_btn', function(e){
    e.preventDefault();
    if ($(this).attr("id") == 'settings_mod_btn'){
        // change button
        $('#settings_mod_btn').attr('hidden', true);
        $('#settings_save_btn').attr('hidden', false);

        // editable
        $('#settings_form').children('p').each(function(index, element){
            $(element).find('input').prop('readonly', false);
        });
    }
    else if ($(this).attr("id") == 'settings_save_btn'){
        // post
        var form = $('#settings_form');
        var actionUrl = form.attr('action');
        
        /*
        var data = {};
        form.serializeArray().map(function(x){data[x.name] = x.value;}); 
        $('#modal').load(actionUrl + ' .modal-dialog', data, function(e){
            // change button
            $('#settings_mod_btn').attr('hidden', false);
            $('#settings_save_btn').attr('hidden', true);

            // not editable
            $('#settings_form').children('p').each(function(index, element){
                $(element).find('input').prop('readonly', true);
            });
        });
        $('#modal').modal();
        */
        
        //data = form.serialize();
        // Use FormData instead of serialize when sending files
        var data = new FormData(form.get(0));
        $.ajax({
            type: "POST",
            dataType: "html",
            url: actionUrl,
            data: data,
            cache: false,
            processData: false,
            contentType: false,
            success: function (response) {
                
            }
        }).done(function (response){
            // https://stackoverflow.com/questions/33119394/how-to-replace-the-html-or-the-return-value-in-ajax
            $('#modal').html(
                // emulate load function in ajax
                // code: https://github.com/jquery/jquery/blob/555a50d340706e3e1e0de09231050493d0ad841e/src/ajax/load.js#L62
                jQuery("<div>").append( jQuery.parseHTML( response ) ).find( '.modal-dialog' )
            );

            // change button
            $('#settings_mod_btn').attr('hidden', false);
            $('#settings_save_btn').attr('hidden', true);

            // not editable
            $('#settings_form').children('p').each(function(index, element){
                $(element).find('input').prop('readonly', true);
            });

            $('#modal').modal();
        });
    }
});

// ajax update
$(document).on('change', '.update_btn', function(e){
    var form = $('#settings_form');
    var actionUrl = form.attr('action');

    var data = {};
    form.serializeArray().map(function(x){data[x.name] = x.value;}); 
    $('#modal').load(actionUrl + ' .modal-dialog', data);
    $('#modal').modal();
    /*
    $.ajax({
        type: "POST",
        url: actionUrl + '?mode=userprofile',
        data: data,
        success: function (response) {
            Object.keys(data).forEach(function(key) {
                $('#id_' + key).val(data[key]);
            });
        }
    });*/
});

// next button
$(document).on('click', '.next_btn', function(e){
    var id = $(this).children('label').attr("for");
    // remove id_ from id
    id = id.substring(3);

    //var form = $('#settings_form');
    //var actionUrl = form.attr('action');
    // ref: https://stackoverflow.com/questions/298772/django-template-variables-and-javascript
    var actionUrl = JSON.parse(document.getElementById('action_url').textContent);
    $('#modal').load(actionUrl + '?page=' + id + ' .modal-dialog');
    $('#modal').modal();
});

// player modal
$(document).on('change', '#select_teams', function(e){
    var localteam_id = $(this).find(':selected').val();
    var form = $('#settings_form');
    var actionUrl = new Url(form.attr('action'));
    actionUrl.query.localteam_id = localteam_id

    $('#modal').load(actionUrl.toString() + ' .modal-dialog');
    $('#modal').modal();
});

// image
$(document).on('change', '#id_icon', function(e){
    var form = $('#settings_form');
    var actionUrl = form.attr('action');
    // Use FormData instead of serialize when sending files
    var data = new FormData(form.get(0));
    $.ajax({
        type: "POST",
        dataType: "html",
        url: actionUrl,
        data: data,
        cache: false,
        processData: false,
        contentType: false,
        success: function (response) {
            
        }
    }).done(function (response){
        // https://stackoverflow.com/questions/33119394/how-to-replace-the-html-or-the-return-value-in-ajax
        $('#modal').html(
            // emulate load function in ajax
            // code: https://github.com/jquery/jquery/blob/555a50d340706e3e1e0de09231050493d0ad841e/src/ajax/load.js#L62
            jQuery("<div>").append( jQuery.parseHTML( response ) ).find( '.modal-dialog' )
        );

        $('#modal').modal();
    });
});