$(document).on 'click', '.add', ->
  $this = $(this)
  $loader = $('#loader')
  $backdrop = $('#backdrop')

  $loader.show()
  $backdrop.show()
  $.ajax
    type: 'POST'
    url: '/add'
    data:
      video_id: $(this).prev('input').val()
    success: ->
      setTimeout ->
        $loader.hide()
        $backdrop.hide()
        $this.children('span').removeClass('glyphicon-plus')
        $this.children('span').addClass('glyphicon-ok')
      , 1000
      $this.attr('disabled','disabled')

  return false
