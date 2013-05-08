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
  ), "Only letters and numbers are allowed"

  $.validator.setDefaults
    onsubmit:     true
    onkeyup:      false
    onfocusout:   false
    onclick:      false
    errorClass:   'help-inline'
    errorElement: 'p'
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

  $(document).activateForms()
