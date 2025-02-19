# A layout that shows entities in sub views according to the input it receives
# and let the user select those entities for merge

mergeEntities = require './editor/lib/merge_entities'
forms_ = require 'modules/general/lib/forms'
error_ = require 'lib/error'
DeduplicateAuthors = require './deduplicate_authors'
DeduplicateWorks = require './deduplicate_works'

module.exports = Marionette.LayoutView.extend
  id: 'deduplicateLayout'
  attributes:
    # Allow the view to be focused by clicking on it, thus being able to listen
    # for keydown events
    tabindex: '0'
  template: require './templates/deduplicate_layout'
  regions:
    content: '.content'

  ui:
    nextButton: '.next'

  behaviors:
    AlertBox: {}

  initialize: ->
    @mergedUris = []
    @_lastMergeTimestamp = 0

  onShow: ->
    # Give focus to controls so that we can listen for keydown events
    # and that hitting tab gives focus to the filter input
    @$el.find('.controls').focus()

    { uris } = @options
    unless _.isNonEmptyArray uris
      uris = app.request('querystring:get', 'uris')?.split('|')

    if _.isNonEmptyArray uris then @loadFromUris uris
    else @showDeduplicateAuthors app.request('querystring:get', 'name')

  loadFromUris: (uris)->
    app.request 'get:entities:models', { uris }
    .then _.Log('entities')
    .then (entities)=>
      # Guess type from first entity
      { type } = entities[0]
      switch type
        when 'human'
          if entities.length is 1 then return @showDeduplicateAuthorWorks entities[0]
        when 'work' then return @showDeduplicateWorks entities

      # If we haven't returned at this point, it is a non handled case
      alert 'case not handled yet'

  showDeduplicateAuthorWorks: (author)->
    author.fetchWorksData()
    .then (worksData)=>
      # Ignoring series
      uris = worksData.works.map _.property('uri')
      app.request 'get:entities:models', { uris }
      .then @showDeduplicateWorks.bind(@)

  showDeduplicateWorks: (works)->
    works = works.filter (entity)-> entity.type is 'work'
    @content.show new DeduplicateWorks { works, @mergedUris }

  showDeduplicateAuthors: (name)->
    @content.show new DeduplicateAuthors { name, @mergedUris }

  serializeData: -> { @uris }

  events:
    'click .workLi,.authorLayout': 'select'
    'click .merge': 'mergeSelected'
    'click .next': 'next'
    'keydown input[name="filter"]': 'lazyFilterByText'
    'keydown': 'triggerActionByKey'
    'next:button:hide': -> @ui.nextButton.hide()
    'next:button:show': -> @ui.nextButton.show()
    'entity:select': 'selectFromUri'

  select: (e)->
    # Prevent selecting when the intent was clicking on a link
    if e.target.tagName is 'A' then return

    $target = $(e.currentTarget)
    uri = getTargetUri e
    $currentlySelected = $('.selected-from, .selected-to')

    switch $currentlySelected.length
      when 0 then $target.addClass 'selected-from'
      when 1
        if $target[0] isnt $currentlySelected[0]
          if getElementType($target[0]) is getElementType($currentlySelected[0])
            $target.addClass 'selected-to'
          else
            $currentlySelected.removeClass 'selected-from selected-to'
            $target.addClass 'selected-from'
      else
        $currentlySelected.removeClass 'selected-from selected-to'
        $target.addClass 'selected-from'

    # Prevent a click on a work to also trigger an event on the author
    e.stopPropagation()

  selectFromUri: (e, data, bla)->
    { uri, direction } = data
    selectorClassName = "selected-#{direction}"
    $(".#{selectorClassName}").removeClass selectorClassName
    $("[data-uri='#{uri}']").addClass selectorClassName

  mergeSelected: ->
    # Prevent merging several times within half a second: it is probably a mistake
    # like the merge key being inadvertedly pressed several times
    if Date.now() - @_lastMergeTimestamp < 500 then return
    @_lastMergeTimestamp = Date.now()

    fromUri = getElementUri $('.selected-from')[0]
    toUri = getElementUri $('.selected-to')[0]

    unless fromUri? then return alert "no 'from' URI"
    unless toUri? then return alert "no 'to' URI"

    mergeEntities fromUri, toUri
    .catch error_.Complete('.buttons-wrapper', false)
    .catch forms_.catchAlert.bind(null, @)

    # Optimistic UI: do not wait for the server response to move on
    @afterMerge fromUri

  afterMerge: (fromUri)->
    hideMergedEntities()
    @mergedUris.push fromUri
    $('.selected-from').removeClass 'selected-from'
    $('.selected-to').removeClass 'selected-to'
    @content.currentView.onMerge?()
    # If @_previousText was set, re-filter using it and the updated mergeUris list
    # otherwise just filter with the updated mergeUris list
    @setSubviewFilter @_previousText

  lazyFilterByText: (e)->
    @_lazyFilterByText or= _.debounce @filterByText.bind(@), 200
    @_lazyFilterByText e
    # Prevent the event to be propagated to the general 'keydown' event
    e.stopPropagation()

  filterByText: (e)->
    text = e.target.value
    if text is @_previousText then return
    @_previousText = text
    @setSubviewFilter text

  setSubviewFilter: (text)->
    @content.currentView.setFilter getFilter(text, @mergedUris)

  next: -> @content.currentView.next?()

  triggerActionByKey: (e)->
    switch e.key
      when 'm' then @mergeSelected()
      when 'n' then @next()

getElementUri = (el)-> el?.attributes['data-uri'].value
getTargetUri = (e)-> getElementUri e.currentTarget
getElementType = (el)-> if $(el).hasClass('authorLayout') then 'author' else 'work'

hideMergedEntities = ->
  $from = $('.selected-from')
  if $from.hasClass 'workLi'
    $author = $from.parents('.authorLayout')
    # If it was the last work, hide the whole author as it should have been turned
    # into a redirection
    if $author.find('.workLi').length is 1 then $author.hide()
    else $from.hide()
  else if $from.hasClass 'authorLayout'
    $from.hide()

getFilter = (text, mergedUris)->
  if _.isNonEmptyString text
    re = new RegExp text, 'i'
    return (model)-> anyLabelMatch(model, re) and model.get('uri') not in mergedUris
  else
    return (model)-> model.get('uri') not in mergedUris

anyLabelMatch = (model, re)->
  labels = _.values(model.get('labels'))
  return _.any labels, (label)-> label.match(re)
