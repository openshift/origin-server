$ = jQuery

$ ->
  $.validator.addMethod "aws_account", ((value) ->
    (/^[\d]{4}-[\d]{4}-[\d]{4}$/).test value
  ), "Account numbers should be a 12-digit number separated by dashes. Ex: 1234-5678-9000"

  $.validator.addMethod "alpha_numeric", ((value) ->
    (/^[A-Za-z0-9]*$/).test value
  ), "Only letters and numbers are allowed"

  $.validator.addClassRules
    domain_name:
      required: true
      alpha_numeric: true
    application_name:
      required: true
      alpha_numeric: true

  $('#new_web_user').validate
    rules:
      # Require email for new users
      "web_user[email_address]":
        required:   true
        email:      true  # Validation handled by HTML5 now
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
  $('#new_application').validate
    errorLabelContainer: '#app-errors ul'
    errorContainer: '#app-errors'
    errorElement: 'li'

  $("#new_domain form").validate
    errorLabelContainer: '#app-errors ul'
    errorContainer: '#app-errors'
    errorElement: 'li'
