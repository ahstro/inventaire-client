require('lib/uncatched_error_logger').initialize()
require('lib/handlebars_helpers').initialize()


window.sharedLib = sharedLib = require('lib/shared/shared_libs')

app = require 'app'
window.app = app

_ = require('lib/builders/utils')(Backbone, window._, app, window)

window.wd = require 'lib/wikidata'

require('lib/global_libs_extender')(_)

# gets all the routes used in the app
app.API = require 'api'

# makes all the require's accessible from app
# might be dramatically heavy from start though
# -> should be refactored to make them functions called at run-time?
_.extend app, require 'structure'

# constructor for interactions between module and LevelDb/IndexedDb
app.LocalCache = require('lib/local_cache')

# setting reqres to trigger methods on data:ready events
app.data = require('lib/data_state')
app.data.initialize()

app.lib.i18n.initialize(app)

# initialize all the modules and their routes before app.start()
# the first routes initialized have the lowest priority

# /!\ routes defined before Redirect will be overriden by the glob
app.module 'Redirect', require 'modules/redirect'
# Users and Entities need to be initialize for the Welcome item panel to work
app.module 'Users', require 'modules/users/users'
app.module 'Entities', require 'modules/entities/entities'
app.module 'User', require 'modules/user/user'
app.module 'Search', require 'modules/search/search'
app.module 'Inventory', require 'modules/inventory/inventory'
if app.user.loggedIn
  app.module 'Profile', require 'modules/profile'
  app.module 'Listings', require 'modules/listings'
  app.module 'Notifications', require 'modules/notifications/notifications'


app.request('i18n:set')
.done ->

  # Initialize the application on DOM ready event.
  $ ->
    # initialize layout after user to get i18n data
    app.layout = new app.Layout.App
    app.lib.foundation.initialize(app)
    app.execute 'show:user:menu:update'

    app.start()

require('lib/jquery-jk').initialize($)
require('lib/svg_inliner').initialize($)
_.ping()