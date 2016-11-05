error_ = require 'lib/error'
Entity = require '../models/entity'
{ get:entitiesGet } = app.API.entities

# In-memory cache for all entities used during a session.
# It's ok to attach it to window for inspection purpose
# as we aren't letting it a chance to be garbage collected anyway
# Each value can be either an entity model or a promise of an entity model.
# Once resolved, the promise object will be replaced by the entity model.
# The main vertue of this is to allow to request an entity only once and then mutualize
# the generated promise between several consumers.
# The only known dupplicate request remaining is when an entity is requested from
# an alias uri and then re-requested from its canonical uri before the first entity
# returned.
window.entitiesModelsIndexedByUri = entitiesModelsIndexedByUri = {}

exports.get = (params)->
  { uris, refresh } = params
  uris = _.uniq uris

  if refresh then missingUris = uris
  else missingUris = getMissingUris uris

  if missingUris.length > 0
    _.log missingUris, 'missingUris'
    # Populate entitiesModelsIndexedByUri with promises of entity models
    # for the missing entities
    populateIndexWithMissingEntitiesModelsPromises missingUris

  # Return a promise that should resolved to an object
  # with all the requested entities models
  return pickEntitiesModelsPromises uris

getMissingUris = (uris)->
  foundUris = Object.keys entitiesModelsIndexedByUri
  return _.difference uris, foundUris

# This is where the magic happens: we are picking values from an object made of
# entity models and promises of entity models, but Promise.props transforms it into
# a unique promise of an index of entity models
pickEntitiesModelsPromises = (uris)->
  Promise.props _.pick(entitiesModelsIndexedByUri, uris)

populateIndexWithMissingEntitiesModelsPromises = (uris, refresh)->
  getEntitiesPromise = getRemoteEntitiesModels uris, refresh
  for uri in uris
    # Populate the index with individual promises
    entitiesModelsIndexedByUri[uri] = inidivualPromise getEntitiesPromise, uri
  # But return nothing: let pickEntitiesModelsPromises take what it needs from those
  return

getRemoteEntitiesModels = (uris, refresh)->
  _.preq.get entitiesGet(uris, refresh)
  .then (res)->
    { entities:entitiesData, redirects } = res

    newEntities = {}
    for uri, entityData of entitiesData
      currentIndexValue = entitiesModelsIndexedByUri[uri]
      # In the case an entity was requested from two different uris (e.g. the canonical
      # and an alias), checking the current index value allows to prevent initializing
      # twice a same model
      if _.isModel currentIndexValue
        newEntities[uri] = currentIndexValue
      else
        newEntities[uri] = new Entity entityData

    aliasRedirects newEntities, redirects
    logMissingEntities newEntities, uris

    # Replace the entities models promises by their models:
    # saves the extra space taken by the promise object
    _.extend entitiesModelsIndexedByUri, newEntities

    return newEntities
  .catch _.ErrorRethrow('get entities data err')

inidivualPromise = (collectivePromise, uri)->  collectivePromise.then _.property(uri)

# Add links to the redirected entities objects
aliasRedirects = (entities, redirects)->
  for from, to of redirects
    entities[from] = entities[to]
  return

logMissingEntities = (newEntities, requestedUris)->
  newEntitiesUris = Object.keys newEntities
  missingUris = _.difference requestedUris, newEntitiesUris
  if missingUris.length > 0
    _.error missingUris, 'entities not found'

# Used when an entity is created locally and needs to be added to the index
exports.add = (entityData)->
  { uri } = entityData
  unless _.isEntityUri uri then throw error_.new "invalid uri: #{uri}", entityData
  return entitiesModelsIndexedByUri[uri] = new Entity entityData
