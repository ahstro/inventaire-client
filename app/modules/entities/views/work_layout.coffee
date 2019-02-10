WorkInfobox = require './work_infobox'
EditionsList = require './editions_list'
EntityActions = require './entity_actions'
entityItems = require '../lib/entity_items'

module.exports = Marionette.LayoutView.extend
  id: 'workLayout'
  className: 'standalone'
  template: require './templates/work_layout'
  regions:
    workInfobox: '#workInfobox'
    editionsList: '#editionsList'
    # Prefix regions selectors with 'work' to avoid collisions with editions
    # displayed as sub-views
    entityActions: '.workEntityActions'
    personalItemsRegion: '.workPersonalItems'
    networkItemsRegion: '.workNetworkItems'
    publicItemsRegion: '.workPublicItems'
    mergeSuggestionsRegion: '.mergeSuggestions'

  initialize: ->
    entityItems.initialize.call @
    @displayMergeSuggestions = app.user.isAdmin

  serializeData: ->
    _.extend @model.toJSON(),
      displayMergeSuggestions: @displayMergeSuggestions

  onShow: ->
    @showWorkInfobox()

    # Need to wait to know if the user has an instance of this work
    @waitForItems
    .then @ifViewIsIntact('showEntityActions')

    @model.waitForSubentities
    .then @ifViewIsIntact('showEditions')

  onRender: ->
    @lazyShowItems()
    if @displayMergeSuggestions then @showMergeSuggestions()

  events:
    'click a.showWikipediaPreview': 'toggleWikipediaPreview'

  showWorkInfobox: ->
    @workInfobox.show new WorkInfobox { @model, standalone: true }

  showEntityActions: -> @entityActions.show new EntityActions { @model }

  showEditions: ->
    @editionsList.show new EditionsList
      collection: @model.editions
      work: @model
      onWorkLayout: true

  toggleWikipediaPreview: -> @$el.trigger 'toggleWikiIframe', @

  showMergeSuggestions: ->
    app.execute 'show:merge:suggestions', { @model, region: @mergeSuggestionsRegion }
