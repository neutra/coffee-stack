require('../../lib/coffee_stack').patch(__dirname)

class TestClass
  innerError: ->
    throw new Error __filename

  outterErrorWithSourceMap: () ->
    c = require './with_sourcemap'
    c.run()

  outterErrorWithoutSourceMap: () ->
    c = require './without_sourcemap'
    c.run()

exports.run = (test) ->
  obj = new TestClass()
  for k,v of obj
    try
      v.apply obj
    catch err
      console.log err.stack

  test.done()

_main = ->
  test = done: -> console.log "test.done()"
  exports.run test

if require.main is module
  _main()