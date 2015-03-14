fieldTests = require 'modules/general/lib/field_tests'

module.exports =
  validate: (options)->
    fieldTests.validate _.extend options,
      field: 'password'
      value: options.password
      tests: passwordTests

  invalidpassword: (err, selector)->
    fieldTests.invalidValue @, err, 'password', selector

passwordTests =
  'password should be 8 characters minimum' : (password)->
    password.length < 8