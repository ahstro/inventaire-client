check = require 'views/behaviors/templates/success_check'
tip = require 'views/behaviors/templates/tip'
input = require 'views/behaviors/templates/input'
link = require 'views/behaviors/templates/external_link'
wdQ = require 'views/behaviors/templates/wikidata_Q'

module.exports =
  initialize: ->
    # Registering partials using the code here
    # https://github.com/brunch/handlebars-brunch/issues/10#issuecomment-38155730
    register = (name, fn) ->
      Handlebars.registerHelper name, fn

    register 'partial', (name, context, option) ->
      template = require "views/templates/#{name}"
      str = new Handlebars.SafeString template(context)
      switch option
        when 'check' then str = new Handlebars.SafeString check(str)
      return str

    register 'firstElement', (obj) ->
      if _.isArray obj
        return obj[0]
      else if typeof obj is 'string'
        return obj
      else
        return

    register 'icon', (name, classes) ->
      name = name || 'cube'
      if typeof classes is 'string' and classes.length > 0
        new Handlebars.SafeString "<i class='fa fa-#{name} #{classes}'></i>&nbsp;"
      else new Handlebars.SafeString "<i class='fa fa-#{name}'></i>&nbsp;"

    register 'i18n', (key, args, context)-> new Handlebars.SafeString _.i18n(key, args, context)

    register 'P', (id)->
      if /^P[0-9]+$/.test id
        new Handlebars.SafeString "class='qlabel wdP' resource='https://www.wikidata.org/entity/#{id}'"
      else new Handlebars.SafeString "class='qlabel wdP' resource='https://www.wikidata.org/entity/P#{id}'"

    register 'Q', (id)->
      if /^Q[0-9]+$/.test id
        new Handlebars.SafeString "class='qlabel wdQ' resource='https://www.wikidata.org/entity/#{id}'"
      else new Handlebars.SafeString "class='qlabel wdQ' resource='https://www.wikidata.org/entity/Q#{id}'"

    register 'claim', (claims, P)->
      if claims?[P]?
        values = claims[P].map (Q)-> wdQ({id: Q})
        return new Handlebars.SafeString values.join ', '
      else
        _.log arguments, 'claim couldnt be displayed by Handlebars'
        return

    register 'limit', (text, limit)->
      if text?
        t = text[0..limit]
        if text.length > limit
          t += '[...]'
        new Handlebars.SafeString t
      else ''

    register 'tip', (text, position)->
      context =
        text: _.i18n text
        position: position || 'rigth'
      new Handlebars.SafeString tip(context)

    register 'placeholder', (height=250, width=200)->
      _.placeholder(height, width)

    register 'input', (data, options)->
      unless data?
        _.log arguments, 'input arguments @err'
        throw new Error 'no data'

      # default data, overridident by arguments
      field =
        type: 'text'
      button =
        classes: 'success postfix'

      name = data.nameBase
      if name?
        field.id = name + 'Field'
        field.placeholder = _.i18n(name)
        button.id = name + 'Button'
        button.text = name

      if data.button?.icon?
        data.button.text = "<i class='fa fa-#{data.button.icon}'></i>"

      # data overriding happens here
      data =
        id: "#{name}Group"
        field: _.extend field, data.field
        button: _.extend button, data.button

      if data.special
        data.special = 'autocorrect="off" autocapitalize="off" autocomplete="off"'

      i = new Handlebars.SafeString input(data)

      if options is 'check' then new Handlebars.SafeString check(i)
      else i

    register 'pre', (text)->
      if text
        text = text.replace /\n/g, '<br>'
        new Handlebars.SafeString text
      else return

    register 'ifvalue', (attr, value)->
      if value? then "#{attr}=#{value}"
      else return

    register 'externalLink', (href, text)->
      attrs =
        href: href
        text: text
      new Handlebars.SafeString link(attrs)

