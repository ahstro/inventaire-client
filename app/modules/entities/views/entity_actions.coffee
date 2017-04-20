module.exports = Marionette.ItemView.extend
  template: require './templates/entity_actions'
  className: 'entityActions'
  behaviors:
    PreventDefault: {}

  initialize: ->
    @uri = @model.get 'uri'
    @mainUserInstances = app.request 'item:main:user:instances', @uri

  serializeData: ->
    mainUserHasOne: @mainUserHasOne()
    instances:
      count: @mainUserInstances.length
      pathname: @mainUserInstancesPathname()

  events:
    'click .add': 'add'
    'click .hasAnInstance a': 'showMainUserInstances'

  add: ->
    if @options.onAdd? then @options.onAdd()
    else app.execute 'show:item:creation:form', { entity: @model }

  mainUserHasOne: ->  @mainUserInstances.length > 0
  showMainUserInstances: -> app.execute 'show:items', @mainUserInstances
  mainUserInstancesPathname: ->
    uri = @uri
    username = app.user.get 'username'
    return "/inventory/#{username}/#{uri}"
