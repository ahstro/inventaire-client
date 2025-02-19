wd_ = require 'lib/wikimedia/wikidata'

module.exports =
  getExtendedAuthorsModels: ->
    Promise.props
      'wdt:P50': @getModelsFromClaims 'wdt:P50'
      'wdt:P58': @getModelsFromClaims 'wdt:P58'
      'wdt:P110': @getModelsFromClaims 'wdt:P110'
      'wdt:P6338': @getModelsFromClaims 'wdt:P6338'

  getModelsFromClaims: (property)->
    uris = @get "claims.#{property}"
    if uris?.length > 0 then app.request 'get:entities:models', { uris }
    else Promise.resolve []

  getExtendedAuthorsUris: ->
    _.chain authorProperties
    .map (property)=> @get "claims.#{property}"
    .compact()
    .flatten()
    .uniq()
    .value()

authorProperties = [
  'wdt:P50'
  'wdt:P58'
  'wdt:P110'
  'wdt:P6338'
]
