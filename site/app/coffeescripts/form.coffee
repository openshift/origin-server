$ = jQuery

$ ->
  $.validator.addMethod "aws_account", ((value) ->
    (/^[\d]{4}-[\d]{4}-[\d]{4}$/).test value
  ), "Account numbers should be a 12-digit number separated by dashes. Ex: 1234-5678-9000"

  $.validator.addMethod "alpha_numeric", ((value) ->
    (/^[A-Za-z0-9]*$/).test value
  ), "Only letters and numbers are allowed"

  $.validator.setDefaults
    errorClass:   'help-inline'
    errorElement: 'p'
    highlight: (element,errorClass,validClass) ->
      $(element).closest('.control-group').addClass('error').removeClass(validClass)
    unhighlight: (element,errorClass,validClass) ->
      $(element).closest('.control-group').addClass(validClass).removeClass('error')

  $('#new_web_user').validate
    rules:
      # Require email for new users
      "web_user[email_address]":
        required:   true
        email:      true
      # Require old password for password change
      "web_user[old_password]" :
        required:   true
      "web_user[password]":
        required:   true
        minlength:  6
      "web_user[password_confirmation]":
        required:   true
        equalTo:    "#web_user_password"

  $('#login-form form').validate
    rules:
      "login":
        required: true
      "password":
        required: true

  $('#password-reset-form form').validate
    rules:
      "email":
        required: true
        email: true

 # Validate application name
  $.validator.addClassRules
    domain_name:
      required: true
      alpha_numeric: true
    application_name:
      required: true
      alpha_numeric: true

  # These forms are inline, so we need to handle them differently
  $('#new_application').validate
    errorLabelContainer: '#app-errors'
    errorContainer: '#app-errors'

  $("#new_domain form").validate
    errorLabelContainer: '#app-errors'
    errorContainer: '#app-errors'

  $('#domain_name_group').closest('form').validate
    errorLabelContainer: '#app-errors'
    errorContainer: '#app-errors'
