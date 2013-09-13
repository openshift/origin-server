$ = jQuery

$ -> 

  # Ties clickable areas (.tile-click) to a particular link (a.tile-target)
  $('.tile-click').click((evt) ->
    if ((t = $(evt.target)) && t.is('a'))
      return
    a = $('a.tile-target', this)[0]
    if a
      window.location = a.href
  )

  # Shows confirm popups when a link is clicked, dismisses them when a .cancel button is clicked
  $('.confirm-container').each( (i, container) ->
    $container = $(container)
    $link = $container.find('.confirm-link')
    $popover = $container.find('.confirm-popover')

    $link.click( ->
      $link.toggleClass('highlight')
      $container.activateForms()
      return false
    ).popover({
      html: true,
      content: ->
        return $popover.html()
    })

    $container.on('click', '.cancel', ->
      $link.popover('hide')
      return false
    ).on('submit', 'form', ->
      $container.find('.popover .btn').hide()
    )
  )
