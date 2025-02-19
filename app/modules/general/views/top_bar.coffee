{ translate } = require 'lib/urls'
showViews = require '../lib/show_views'
getActionKey = require 'lib/get_action_key'
LiveSearch = require 'modules/search/views/live_search'
screen_ = require 'lib/screen'
{ currentRoute, currentSection } = require 'lib/location'

{ languages } = require 'lib/active_languages'
mostCompleteFirst = (a, b)-> b.completion - a.completion
languagesList = _.values(languages).sort mostCompleteFirst

module.exports = Marionette.LayoutView.extend
  id: 'top-bar'
  tagName: 'nav'
  className: -> if app.user.loggedIn then 'logged-in' else ''
  template: require './templates/top_bar'

  regions:
    liveSearch: '#liveSearch'

  ui:
    searchField: '#searchField'
    overlay: '#overlay'

  initialize: ->
    @lazyRender = _.LazyRender @

    @listenTo app.vent,
      'screen:mode:change': @lazyRender
      'route:change': @onRouteChange.bind(@)
      'live:search:show:result': @hideLiveSearch.bind(@)
      'live:search:query': @setQuery.bind(@)

    @listenTo app.user, 'change:username', @lazyRender
    @listenTo app.user, 'change:picture', @lazyRender

  serializeData: ->
    smallScreen: screen_.isSmall()
    isLoggedIn: app.user.loggedIn
    user: app.user.toJSON()
    currentLanguage: languages[app.user.lang].native
    languages: languagesList
    translate: translate

  onShow: ->
    # Needed as 'route:change' might have been triggered before
    # this view was initialized
    @onRouteChange currentSection(), currentRoute()

  onRouteChange: (section, route)->
    @updateConnectionButtons section

  events:
    'click #home': 'showHome'
    'click #mainUser': 'showMainUser'
    'click a#searchButton': 'search'
    'click .option a': 'selectLang'
    'focus #searchField': 'showLiveSearch'
    'keyup #searchField': 'onKeyUp'
    'keydown #searchField': 'onKeyDown'
    'click .searchFilter': 'recoverSearchFocus'
    'click': 'updateLiveSearch'

  childEvents:
    'hide:live:search': 'hideLiveSearch'

  showHome: (e)->
    unless _.isOpenedOutside e
      app.execute 'show:home'

  showMainUser: (e)->
    unless _.isOpenedOutside e
      app.execute 'show:inventory:user', app.user

  updateConnectionButtons: (section)->
    if app.user.loggedIn then return

    if screen_.isSmall() and (section is 'signup' or section is 'login')
      $('.connectionButton').hide()
    else if not app.user.loggedIn
      $('.connectionButton').show()

  selectLang: (e)->
    # Remove the querystring lang parameter to be sure that the picked language
    # is the next language taken in account
    app.execute 'querystring:set', 'lang', null

    lang = e.currentTarget.attributes['data-lang'].value
    if app.user.loggedIn
      app.request 'user:update',
        attribute:'language'
        value: lang
        selector: '#languagePicker'
    else
      app.user.set 'language', lang

  showLiveSearch: (params = {})->
    if @liveSearch.currentView? then @liveSearch.$el.show()
    else @liveSearch.show new LiveSearch(params)
    @liveSearch.$el.addClass 'shown'
    @liveSearch.currentView.resetHighlightIndex()
    @ui.overlay.removeClass 'hidden'
    @_liveSearchIsShown = true

  hideLiveSearch: (triggerFallbackLayout)->
    # Discard non-boolean flags
    triggerFallbackLayout = triggerFallbackLayout is true

    unless @liveSearch.$el? then return

    @liveSearch.$el.hide()
    @liveSearch.$el.removeClass 'shown'
    @ui.overlay.addClass 'hidden'
    @_liveSearchIsShown = false
    # Trigger the fallback layout only in cases when no other layout
    # is set to be displayed
    if triggerFallbackLayout and @showFallbackLayout?
      @showFallbackLayout()
      @showFallbackLayout = null

  updateLiveSearch: (e)->
    # Make clicks on anything but the search group hide the live search
    { target } = e
    if target.id is 'overlay' or $(target).parents('#searchGroup').length is 0
      @hideLiveSearch true

  onKeyDown: (e)->
    # Prevent the cursor to move when using special keys
    # to navigate the live_search list
    key = getActionKey e
    if key in neutralizedKeys then e.preventDefault()

  onKeyUp: (e)->
    unless @_liveSearchIsShown then @showLiveSearch()

    key = getActionKey e
    if key?
      if key is 'esc' then @hideLiveSearch true
      else @liveSearch.currentView.onSpecialKey key
    else
      { value } = e.currentTarget
      @searchLive value

  searchLive: (text)->
    @liveSearch.currentView.lazySearch text
    app.vent.trigger 'search:global:change', text

  setQuery: (params)->
    { search, @showFallbackLayout, section } = params
    @showLiveSearch { section }
    @searchLive search
    @ui.searchField.focus()
    # Set value after focusing so that the cursor appears at the end
    # cf https://stackoverflow.com/a/8631903/3324977inv
    @ui.searchField.val search

  # When clicking on a live_search searchField button, the search loose the focus
  # thus the need to recover it
  recoverSearchFocus: -> @ui.searchField.focus()

neutralizedKeys = [ 'up', 'down', 'pageup', 'pagedown' ]
