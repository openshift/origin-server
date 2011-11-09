$ = jQuery

$ ->
  $.validator.addMethod "aws_account", ((value) ->
    (/^[\d]{4}-[\d]{4}-[\d]{4}$/).test value
  ), "Account numbers should be a 12-digit number separated by dashes. Ex: 1234-5678-9000"

  $.validator.addMethod "alpha_numeric", ((value) ->
    (/^[A-Za-z0-9]*$/).test value
  ), "Only letters and numbers are allowed"

  $("#new_access_express_request").validate rules:
    "access_express_request[terms_accepted]":
      required: true

  $("#new_access_flex_request").validate rules:
    "access_flex_request[terms_accepted]":
      required: true

  $("#new_express_domain").validate rules:
    "express_domain[namespace]":
      required: true
      alpha_numeric: true
      maxlength: 16
    "express_domain[ssh]":
      required: true
    "express_domain[password]":
      required: true
      minlength: 6
  
  $("#new_express_app").validate rules:
    "express_app[app_name]":
      required: true
      alpha_numeric: true,
      maxlength: 16
    "express_app[cartridge]":
      required: true
      
  #$("input:visible:first").focus()

## Dialogs ##
  dialogs = $ '.dialog'

  open_dialog = (dialog) ->
    # Close any other open dialogs
    dialogs.hide()
    # Show given dialog
    dialog.show()
    # Put focus in the first visible box
    dialog.find("input:visible:first").focus()
    # scroll to top
    ($ window, 'html', 'body').scrollTop 0

  close_dialog = (dialog) ->
    dialog.find('div.message').remove()
    dialog.find('input:visible:not(.button)').val('')
    dialog.find('label.error').remove()
    dialog.find('input').removeClass('error')
    dialog.hide()
    
  # Close buttons
  close_btn = $ '.close_button'
  # Sign up dialog
  signup = $ '#signup'
  # Sign in dialog
  signin = $ '#signin'
  # Password reset dialog
  reset  = $ '#reset_password'
  # Change password dialog
  change = $ '#change_password'

  ($ 'a.sign_up').click (event) ->
    event.preventDefault()
    open_dialog signup

  ($ 'a.sign_in').click (event) ->
    event.preventDefault()
    login = $ 'div.content #login-form'
    userbox = $ '#user_box #login-form'
    if login.length > 0 || userbox.length > 0
      dialogs.hide()
      $('#login_input').focus()
    else
      open_dialog signin

  ($ 'a.password_reset').click (event) ->
    event.preventDefault()
    open_dialog reset

  ($ 'a.change_password').click (event) ->
    event.preventDefault()
    open_dialog change
    
  close_btn.click (event) ->
    close_dialog ($ this).parent()

  # Function based on definitions in rails.js:
  login_complete = (xhr,status) ->
    ($ this).spin(false)

    json = $.parseJSON( status.responseText )
    console.log json
    # Clear out error messages
    $(this).parent().find('div.message.error').remove()
    $err_div = $('<div>').addClass('message error').hide().insertBefore(this)

    switch status.status
        when 200 #everything ok
          window.location.replace json.redirectUrl
          break
        when 401 #Unauthorized
          $err_div.text(json.error).show()
          break
        else
          $err_div.html(json.error || "Some unknown error occured,<br/> please try again.").show()
          console.log 'Some unknown AJAX error with the login', status.status

  registration_complete = (xhr,status) ->
    ($ this).spin(false)

    form = $(this)
    json = $.parseJSON( status.responseText )
    console.log "Reg complete, got JSON", json

    # Clear out error messages
    $(this).parent().find('div.message.error').remove()
    $err_div = $('<div>').addClass('message error').hide().insertBefore(this)

    # Save all errors
    messages = $.map(json, (k,v) -> return k)

    if( json['redirectUrl'] == undefined || json['redirectUrl'] == null )

      $.each(messages, (i,val)->
        $err_div.addClass('error').append($('<div>').html(val))
      )
      $err_div.show()

      if typeof Recaptcha != 'undefined'
        Recaptcha.reload()
    else
      window.location.replace json['redirectUrl']

  reset_password_complete = (xhr,status) ->
    ($ this).spin(false)

    form = $(this)
    json = $.parseJSON( status.responseText )
    console.log "Reset password complete, got JSON", json

    $(this).parent().find('div.message').remove()
    $div = $('<div>').addClass("message #{json.status}").text(json.message).insertBefore(this)

  start_spinner = (form) ->
    ($ form).spin()
    $(form).ajaxSubmit()

  # Bind the forms
  $.each [signin, ($ '#login-form')], (index,element) ->
    element.find('form').bind('ajax:complete', login_complete ).validate 
      submitHandler: 
        start_spinner
      rules:
        "login":
          required: true
        "password":
          required: true

  $.each [signup, $( '#new-user')], (index, element) ->
    element.find('form').bind('ajax:complete', registration_complete).validate 
      submitHandler: 
        start_spinner
      rules:
        "web_user[email_address]":
          required: true
          email: true
        "web_user[password]":
          required: true
          minlength: 6
        "web_user[password_confirmation]":
          required: true
          equalTo: "#web_user_password"

  change.find('form').bind('ajax:complete', reset_password_complete).validate 
    submitHandler: 
      start_spinner
    rules:
      "old_password":
        required: true
      "password":
        required: true
        minlength: 6
      "password_confirmation":
        required: true
        equalTo: '#password'

  reset.find('form').bind('ajax:complete', reset_password_complete).validate 
    submitHandler: 
      start_spinner
    rules:
      "email":
        required: true
        email: true
