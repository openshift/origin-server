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

  # validates that a given value must be in all of the given arrays
  $.validator.addMethod "in_all_arrays", ((value, element, arrays) ->
    if $.isArray(arrays)
      for array in arrays 
        if $.isArray(array) && $.inArray(value, array) == -1
          return false
      return true
    else
      return false
  )

  # makes sure the gear sizes selected are not mutually exclusive in case of multiple cartridges
  $.validator.addMethod "intersected_cartridge_sizes", ((value) ->
    $intersected_cartridge_sizes = true

    for current in $("select[name='application[cartridges][]'] option:selected, input[name='application[cartridges][]']")
      $current_cart_gear_sizes = $(current).data("gear-sizes")

      if $current_cart_gear_sizes? && $intersected_cartridge_sizes
        for other in $("select[name='application[cartridges][]']").not($(current).parent()).children("option:selected")
          $other_cart_gear_sizes = $(other).data("gear-sizes")

          if $other_cart_gear_sizes? && $intersected_cartridge_sizes
            $other_cart_gear_sizes = $other_cart_gear_sizes.split(',')

            if $current_cart_gear_sizes.split(',').filter((n) ->
              return $.inArray(n, $other_cart_gear_sizes) > -1
            ).length == 0
              $intersected_cartridge_sizes = false

    return $intersected_cartridge_sizes
  ), "The cartridges selected require gear sizes that are not compatible with each other."

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
        in_all_arrays: (element) ->
          $domain_sizes = $(element).closest('form').find('select#application_domain_name option:selected').data('gear-sizes')
          
          $cartridge_sizes = application_type_valid_gear_sizes ? null

          $quickstart_sizes = has_multiple_cartridge_types ? null

          if $quickstart_sizes
            $cart_sizes = []
            $(element)
              .closest('form')
              .find('#application_cartridges select option:selected, #application_cartridges input[type=hidden]')
              .each((i) ->
                if $(this).data('gear-sizes')
                  $cart_sizes.push($(this).data('gear-sizes').split(','))
              )

            if $cart_sizes.length > 0
              $quickstart_sizes = 
                $cart_sizes.sort((a, b) ->
                  return a.length - b.length
                ).shift().filter((v) ->
                  return $cart_sizes.every((a) ->
                    return a.indexOf(v) != -1
                  )
                )  
            else 
              $quickstart_sizes = null

          if $domain_sizes == ""
            $domain_sizes = []
          else if !$domain_sizes
            $domain_sizes = null
          else
            $domain_sizes = $domain_sizes.split(',')

          [$domain_sizes, $quickstart_sizes ? $cartridge_sizes]
      "application[cartridges][]":
        intersected_cartridge_sizes: (element) ->
          element
    messages:
      "application[gear_profile]":
        in_all_arrays: (params, element) ->
          if $.isArray(params)
            if $.isArray(params[0]) && params[0].length == 0
              "The owner of the selected domain has disabled all gear sizes from being created. You will not be able to create an application in this domain."
            else
              if $.isArray(params[1]) && $.inArray($(element).val(), params[1]) == -1
                $number_of_carts = $('#application_cartridges select option:selected, #application_cartridges input[type=hidden]').length
                jQuery.format("The gear size <strong>{0}</strong> is not supported by this <strong>{1}</strong>.{2}", $(element).val(), (if $number_of_carts > 1 then 'set of cartridges' else 'cartridge'), (if params[1].length == 0 then '' else " Allowed: " + params[1].join(', ') + "."))
              else
                jQuery.format("The gear size <strong>{0}</strong> is not valid for the selected <strong>domain</strong>. Allowed for domain: {1}.", $(element).val(), params[0].join(', '))

  $(document).activateForms()
