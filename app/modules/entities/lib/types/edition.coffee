{ unprefixifyEntityId } = require 'lib/wikimedia/wikidata'
wdLang = require 'wikidata-lang'
farInTheFuture = '2100'

module.exports = ->
  _.extend @, specificMethods
  @setClaimsBasedAttributes()

  uri = @get 'uri'
  workUri = @get 'claims.wdt:P629.0'

  # Editions don't have subentities so the list of all their uris,
  # including their subentities, are limited to their own uri
  @set 'allUris', [ uri ]

  # No subentities to fetch
  @waitForSubentities = _.preq.resolved

  @waitForWork = @reqGrab 'get:entity:model', workUri, 'work'
  # Use tap to ignore the return values
  .tap inheritData.bind(@)
  # Got to be initialized after inheritData is run to avoid running
  # several times at initialization
  .tap startListeningForClaimsChanges.bind(@)

  return

# Editions inherit claims like author 'wdt:P50' from their work
inheritData = (work)->
  unless @get('label')? then @set 'label', @work.get('label')
  claims = @get 'claims'
  workClaims = work.get 'claims'
  @set 'claims', _.extend({}, workClaims, claims)
  return

startListeningForClaimsChanges = ->
  @on 'change:claims', @setClaimsBasedAttributes.bind(@)
  # Do no return the event listener return value as it makes Bluebird crash
  # (at least when passed to a .then)
  return

specificMethods =
  getAuthorsString: -> @waitForWork.then (work)-> work.getAuthorsString()
  buildTitleAsync: -> @waitForWork.then (work)-> work.buildTitle()

  setLang: ->
    langUri = @get 'claims.wdt:P407.0'
    lang = if langUri then wdLang.byWdId[unprefixifyEntityId(langUri)]?.code
    @set 'lang', lang

  setLabelFromTitle: ->
    # Take the label from the monolingual title property
    @set 'label', @get('claims.wdt:P1476.0')

  setPublicationTime: ->
    publicationDate = @get 'claims.wdt:P577.0'
    publicationTime = new Date(publicationDate or farInTheFuture).getTime()
    @set 'publicationTime', publicationTime

  setClaimsBasedAttributes: ->
    @setLang()
    @setLabelFromTitle()
    @setPublicationTime()
