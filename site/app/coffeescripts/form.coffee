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
    $.each $('div.dialog:visible'), (index,dialog) ->
      close_dialog $(dialog)

    dialogs.hide()
    # Show given dialog
    dialog.show()
    # Put focus in the first visible box
    dialog.find("input:visible:first").focus()
    # scroll to top
    ($ window, 'html', 'body').scrollTop 0

  close_dialog = (dialog) ->
    dialog.find(':hidden').show()
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
  login_complete = ($form,$msg,$json,status) ->
    switch status
        when 200 #everything ok
          window.location.replace $json.redirectUrl
          break
        when 401 #Unauthorized
          $msg.addClass('error').text($json.error).show()
          break
        else
          $msg.addClass('error').html($json.error || "Some unknown error occured,<br/> please try again.").show()

  registration_complete = ($form,$msg,$json,status) ->
    # Save all errors
    messages = $.map(json, (k,v) -> return k)

    if( $json['redirectUrl'] == undefined || $json['redirectUrl'] == null )
      $.each(messages, (i,val)->
        $msg.addClass('error').append($('<div>').html(val))
      )
      $msg.show()

      if typeof Recaptcha != 'undefined'
        Recaptcha.reload()
    else
      window.location.replace $json['redirectUrl']

  reset_password_complete = ($form,$msg,$json,hide) ->
    $msg.addClass($json.status).text($json.message).show()

    if hide
      $form.parent().find('form,div#extra_options').hide()

  start_spinner = (e) ->
    $form = $( e.target)
    $form.find('input[type=submit]').attr('disabled', 'disabled')
    $form.spin()

  stop_spinner = ($form) ->
    $form.find('input[type=submit]').removeAttr('disabled')
    $form.spin(false)

  form_complete = (xhr, status) ->
    $form = $(this)
    stop_spinner($form)

    # Get the json from the response
    $json = $.parseJSON( status.responseText )

    # Clear all messages and create a new div
    $parent = $form.parent()
    $parent.find('div.message').remove()
    $msg = $('<div>').addClass('message').hide().insertBefore($form)

    type = $form.closest('.dialog').attr('id')
    switch(type)
      when 'signup'
        registration_complete($form, $msg, $json, status.status)
        break
      when 'signin'
        login_complete($form, $msg, $json, status.status)
        break
      when 'reset_password'
        reset_password_complete($form,$msg,$json,true)
        break
      when 'change_password'
        reset_password_complete($form,$msg,$json,false)
        break

    $msg.truncate()

  # The rulesets for form validation
  rulesets =
    reset:
      rules:
        "email":
          required: true
          email: true
    change:
      rules:
        "old_password":
          required: true
        "password":
          required: true
          minlength: 6
        "password_confirmation":
          required: true
          equalTo: '#password'
    signup:
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
    signin:
      rules:
        "login":
          required: true
        "password":
          required: true

  # These correspond to the above rulesets
  form_type = 
    signin: [
      signin
      ($ '#login-form')
    ]
    signup: [
      signup
      ($ '#new-user')
    ]
    change: [
      change
    ]
    reset: [
      reset
    ]

  # Go through each form, bind the ajax functions and apply rulesets
  $.each form_type, (name,forms) ->
    $.each forms, (index,form) ->
      form.find('form')
        .bind('ajax:complete', form_complete )
        .bind('ajax:beforeSend', start_spinner)
        .validate rulesets[name]
