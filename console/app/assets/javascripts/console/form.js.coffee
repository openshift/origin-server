$ = jQuery

find_control_group_parent =
  (child) ->
    parent = $(child).parentsUntil(".control-group").parent().closest(".control-group")
    return parent

$ ->

  #  $.validator.addMethod "aws_account", ((value) ->
  #    (/^[\d]{4}-[\d]{4}-[\d]{4}$/).test value
  #  ), "Account numbers should be a 12-digit number separated by dashes. Ex: 1234-5678-9000"

  $.validator.addMethod "alpha_numeric", ((value) ->
    (/^[A-Za-z0-9]*$/).test value
  ), "Only letters and numbers are allowed."

  $.validator.addMethod "in_array", ((value, element, params) ->
    if $.isArray(params)
      return $.inArray(value, params) >= 0
    else
      return true
  )

  $.validator.setDefaults
    onsubmit:     true
    onkeyup:      false
    onfocusout:   false
    onclick:      false
    errorClass:   'help-inline'
    errorElement: 'p'
    ignoreTitle:  true
    highlight: (element,errorClass,validClass) ->
      $(element).addClass('error')
      $el = find_control_group_parent(element)
      if el = $el.get(0)
        el.highlighted ||= []
        el.highlighted.unshift(element.id)
      $el.addClass('error').addClass('error-client').removeClass(validClass)
    unhighlight: (element,errorClass,validClass) ->
      $(element).removeClass('error')
      $el = find_control_group_parent(element)
      if el = $el.get(0)
        el.highlighted = $.grep (el.highlighted || []), (i) -> i != element.id
        if el.highlighted.length == 0
          $el.removeClass('error-client')
          if typeof($el.attr('data-server-error')) == 'undefined'
            $el.removeClass('error')

  $("[data-unhide]").click (event) ->
    src = $(this)
    tgt = $(src.attr('data-unhide'))
    if (tgt)
      tgt.removeClass('hidden hidden-scripted')
      event.preventDefault() if event?
      src.closest('[data-hide-parent]').addClass('hidden')
      $('input',tgt.removeClass('hidden')).focus()

  # Show/hide loading icons when form buttons are clicked
  $.fn.activateForms = ->
    loading_match = '*[data-loading=true]'
    $(this).find('form ' + loading_match).each ->
      this.src = window.loader_image if window.loader_image
      finished = ->
        ($ loading_match).hide()
        ($ 'input[type=submit][disabled]').removeAttr('disabled')
      ($ window).bind 'pagehide', finished
      ($ this).closest('form').bind 'submit', ->
        if $(this).valid is undefined || $(this).valid()
          this.finished = finished
          if ($ '.control-group.error-client').length == 0
            ($ loading_match, this).show()
            ($ 'input[type=submit]', this).attr('disabled','disabled')
            true
          else
            false
        else
          false

  $('.with-alert-details a, .error-reference a').click (event) ->
    event.preventDefault() if event?
    link = $(this)
    if link.parent().hasClass('error-reference')
      message = $('p.error-reference')
      details = $('.error-reference-details')
    else
      message = link.closest('.with-alert-details')
      details = message.next('.alert-details')
    message.toggleClass('detailed')
    details.toggleClass('hide')
    if link.text() == 'Show more' 
      link.text('Show less')
    else 
      link.text('Show more')

  # application_type/<type>
  $('form#new_application').validate
    ignore: ""
    errorPlacement: (error, el) ->
      controls_block = el.closest('.controls')
      if controls_block.length
        controls_block.append(error)
      else
        error.insertAfter(el)
    rules:
      "application[name]":
        required: true
        rangelength: [1,32]
        alpha_numeric: true
      "application[domain_name]":
        required: true
        rangelength: [1,16]
        alpha_numeric: true
      "application[gear_profile]":
        in_array: (element) ->
          $sizes = $(element).closest('form').find('select#application_domain_name option:selected').data('gear-sizes')
          if $sizes == ""
            []
          else if !$sizes
            null
          else 
            $sizes.split(',')
    messages:
      "application[gear_profile]":
        in_array: (params, element) ->
          if $.isArray(params)
            if params.length == 0
              "The owner of the selected domain has disabled all gear sizes from being created. You will not be able to create an application in this domain."
            else
              jQuery.format("The gear size '{0}' is not valid for the selected domain. Allowed sizes: {1}.", $(element).val(), params.join(', '))

  $(document).activateForms()
