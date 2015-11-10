Filterable = require 'modules/general/models/filterable'

module.exports = Filterable.extend
  setPathname: ->
    username = @get('username')
    @set 'pathname', "/inventory/#{username}"
  asMatchable: ->
    [
      @get('username')
    ]

  hasPosition: -> @has 'position'
  getPosition: ->
    latLng = @get 'position'
    if latLng?
      [ lat, lng ] = latLng
      return { lat: lat, lng: lng }
    else return {}

  updateMetadata: ->
    app.execute 'metadata:update',
      title: @get 'username'
      description: @getDescription()
      image: @get 'picture'
      url: @get 'pathname'

  getDescription: ->
    bio = @get('bio')
    if _.isNonEmptyString bio then return bio
    else _.i18n 'user_default_description', {username: @get('username')}
