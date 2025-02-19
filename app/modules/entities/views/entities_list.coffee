loader = require 'modules/general/views/templates/loader'
error_ = require 'lib/error'
canAddOneTypeList = [ 'serie', 'work' ]
{ buildPath } = require 'lib/location'

# TODO:
# - deduplicate series in sub series https://inventaire.io/entity/wd:Q740062
# - hide seris parts when displayed as sub-series

module.exports = Marionette.CompositeView.extend
  template: require './templates/entities_list'
  className: ->
    standalone = if @options.standalone then 'standalone' else ''
    return "entitiesList #{standalone}"
  behaviors:
    Loading: {}
    PreventDefault: {}

  childViewContainer: '.container'
  getChildView: (model)->
    { type } = model
    switch type
      when 'serie' then require './serie_layout'
      when 'work' then require './work_li'
      when 'article' then require './article_li'
      # Types included despite not being works
      # to make this view reusable by ./claim_layout with those types.
      # This view should thus possibily be renamed entities_list
      when 'edition' then require './edition_layout'
      when 'human' then require './author_layout'
      when 'publisher' then require './publisher_layout'
      else
        err = error_.new "unknown entity type: #{type}", model
        # Weird: errors thrown here don't appear anyware
        # where are those silently catched?!?
        console.error 'entities_list getChildView err', err, model
        throw err

  childViewOptions: (model, index)->
    refresh: @options.refresh
    showActions: @options.showActions
    wrap: @options.wrapWorks

  ui:
    counter: '.counter'
    more: '.displayMore'
    addOne: '.addOne'
    moreCounter: '.displayMore .counter'

  initialize: ->
    initialLength = @options.initialLength or 5
    @batchLength = @options.batchLength or 15

    @fetchMore = @collection.fetchMore.bind @collection
    @more = @collection.more.bind @collection

    # First fetch
    @collection.firstFetch initialLength

    if @options.canAddOne is false then return

    @setEntityCreationData()

    if @options.type in canAddOneTypeList
      @addOneData =
        label: addOneLabels[@options.parentModel.type][@options.type]
        href: @_entityCreationData.href

  setEntityCreationData: ->
    { type, parentModel } = @options
    { type:parentType } =  parentModel

    claims = {}
    prop = parentModel.childrenClaimProperty
    claims[prop] = [ parentModel.get('uri') ]

    if parentType is 'serie'
      claims['wdt:P50'] = parentModel.get 'claims.wdt:P50'

    href = buildPath '/entity/new', { type, claims }

    @_entityCreationData = { type, claims, href }

  serializeData: ->
    title: @options.title
    customTitle: @options.customTitle
    hideHeader: @options.hideHeader
    more: @more()
    totalLength: @collection.totalLength
    addOne: @addOneData

  events:
    'click a.displayMore': 'displayMore'
    'click a.addOne': 'addOne'

  displayMore: ->
    @startMoreLoading()

    @collection.fetchMore @batchLength
    .then =>
      if @more()
        @ui.moreCounter.text @more()
      else
        @ui.more.hide()
        @ui.addOne.removeClass 'hidden'

  startMoreLoading: ->
    @ui.moreCounter.html loader()

  addOne: (e)->
    unless _.isOpenedOutside e
      { type, claims } = @_entityCreationData
      app.execute 'show:entity:create', { type, claims }

addOneLabels =
  # parent model type
  human:
    # list elements type
    work: 'add a work from this author'
    serie: 'add a serie from this author'
  serie:
    work: 'add a work to this serie'
