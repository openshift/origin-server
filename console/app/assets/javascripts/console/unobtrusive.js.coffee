$ = jQuery

$ -> 

  # Ties clickable areas (.tile-click) to a particular link (a.tile-target)
  tileClickHandler = (evt) ->
    if ((t = $(evt.target)) && t.is('a'))
      return
    a = $('a.tile-target', this)[0]
    if a
      if evt.which == 2 || evt.ctrlKey || evt.shiftKey
        window.open(a.href)
      else
        window.location = a.href

  $('.tile-click').click((evt) ->
    if evt.which != 2
      tileClickHandler.apply(this, [evt])
  ).mouseup((evt) ->
    if evt.which == 2
      tileClickHandler.apply(this, [evt])
  )

  # Shows confirm popups when a link is clicked, dismisses them when a .cancel button is clicked
  $('.confirm-container').each( (i, container) ->
    $container = $(container)
    $link = $container.find('.confirm-link')
    $popover = $container.find('.confirm-popover')

    $link.popover({
      html: true,
      content: ->
        return $popover.html()
    }).click( ->
      $link.toggleClass('highlight')
      $container.activateForms()
      return false
    )

    $container.on('click', '.cancel', ->
      $link.popover('hide')
      return false
    ).on('submit', 'form', ->
      $container.find('.popover .btn').hide()
    )
  )

  $forms = $('form.warn-dirty')
  if $forms.length
    dirty = ->
      $(this).closest('form').addClass('dirty').find('.btn-primary-when-dirty').addClass('btn-primary')
    clear = ->
      $(this).closest('form').removeClass('dirty')
    cancel = ->
      $(this).closest('form').removeClass('dirty').find('.btn-primary-when-dirty').removeClass('btn-primary')

    $forms.filter('.dirty').each(dirty)
    $forms.find('input, select, textarea').change(dirty)
    $forms.find('input, textarea').on('input', dirty)
    
    $forms.submit(clear)

    $forms.find('.cancel').click(cancel)
    $forms.on('reset', cancel)

    $(window).on 'beforeunload', ->
      if $('form.warn-dirty.dirty').length
        return "You may lose unsaved changes. Are you sure you want to leave this page?"
