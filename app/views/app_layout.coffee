module.exports = class AppLayout extends Backbone.Marionette.LayoutView
  template: require 'views/templates/app_layout'
  behaviors:
    PreventDefault: {}

  el: 'body'

  regions:
    topMenu: '#topMenu'
    menuBar: '#menuBar'
    viewTools: '#viewTools'
    main: 'main'
    accountMenu: '#accountMenu'
    modal: '#modalContent'

  events:
    'click #home': 'showHome'
    'keyup .enterClick': 'enterClick'
    'click a.back': -> window.history.back()
    'click a#searchButton': 'search'
    'focus #searchField': 'maximizeSearchField'
    'focusout #searchField': 'unmaximizeIfNotAtSearch'
    'click a.wdQ': 'showEntity'

  initialize: (e)->
    @render()
    app.vent.trigger 'layout:ready'
    app.commands.setHandlers
      'show:home': @showHome
      'show:loader': @showLoader
      'show:error': @showError
      'show:403': @show403
      'show:404': @show404
      'main:fadeIn': -> app.layout.main.$el.hide().fadeIn(200)
      'search:field:maximize': @maximizeSearchField
      'search:field:unmaximize': @unmaximizeSearchField

    app.reqres.setHandlers
      'waitForCheck': @waitForCheck

  showLoader: (options)->
    [region, selector, title] = _.pickToArray options, ['region', 'selector', 'title']
    if region?
      region.Show new app.View.Behaviors.Loader, title
    else if selector?
      loader = new app.View.Behaviors.Loader
      $(selector).html loader.render()
      app.docTitle title  if title?
    else
      app.layout.main.Show new app.View.Behaviors.Loader, title

  showHome: ->
    if app.user.loggedIn
      app.execute 'show:inventory:personal'
      app.execute 'main:fadeIn'
    else
      app.execute 'show:welcome'
      app.execute 'main:fadeIn'

  enterClick: (e)->
    if e.keyCode is 13 && $(e.currentTarget).val().length > 0
      row = $(e.currentTarget).parents('.row')[0]
      $(row).find('.button').trigger 'click'
      _.log 'ui: enter-click'

  waitForCheck: (options)->
    _.log options, 'waitForCheck options'
    # $selector or selector MUST be provided
    if options.selector? then $selector = $(options.selector)
    else $selector = options.$selector
    $selector.trigger('loading')

    # action or promise MUST be provided
    if options.action? then promise = options.action()
    else promise = options.promise

    # success and/or error handlers CAN be provided
    promise
    .then (res)-> $selector.trigger('check', options.success)
    .fail (err)-> $selector.trigger('fail', options.error)

    return promise

  show403: ->
    app.execute 'show:error',
      code: 403
      message: _.i18n 'Forbidden'

  show404: ->
    app.execute 'show:error',
      code: 404
      message: _.i18n 'Not Found'

  showError: (options)->
    app.layout.main.show new app.View.Error options

  search: ->
    query = $('input#searchField').val()
    _.log query, 'search query'
    app.execute 'search', query

  maximizeSearchField: -> $('#searchGroup').addClass('maximized')
  unmaximizeSearchField: -> $('#searchGroup').removeClass('maximized')
  unmaximizeIfNotAtSearch: ->
    @unmaximizeSearchField()  unless _.currentLocationMatch '/search'

  showEntity: (e)->
    href = e.target.href
    uri = href.split('/entity/').last()
    app.execute 'show:entity', uri