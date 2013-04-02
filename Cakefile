fs = require 'fs'
path = require 'path'
{spawn,exec} = require 'child_process'

launch = (cmd, args=[], callback) ->
  app = spawn cmd, args, {cwd: process.cwd()}
  app.stdout.pipe process.stdout
  app.stderr.pipe process.stderr
  app.on 'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

clean = ->
  fs.unlinkSync path.join 'lib',file for file in fs.readdirSync 'lib'
  fs.unlinkSync path.join 'test/js',file for file in fs.readdirSync 'test/js'

build = ->
  clean()
  exec "coffee -cm -o lib src", (err) ->
    return if err
    exec "coffee -cm -o \"#{path.join "test","js"}\" \"#{path.join "test","coffee","test.coffee"}\" \"#{path.join "test","coffee","with_sourcemap.coffee"}\"",(err) ->
      return if err
      exec "coffee -c -o \"#{path.join "test","js"}\" \"#{path.join "test","coffee","without_sourcemap.coffee"}\"",(err) ->

task 'build', 'compile source', build

task 'test', 'run test', ->
  launch 'node',[path.join __dirname,"test","js","test.js"],(err) ->
