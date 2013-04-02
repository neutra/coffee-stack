fs = require 'fs'
path = require 'path'
fs.existsSync or= path.existsSync
{SourceMap,vlqDecodeValue} = require './sourcemap'

DEBUG = off

mainModule = require.main

patched = no
patchStackTrace = ->
  return if patched
  patched = yes
  mainModule._sourceMaps or= {}
  try
    coffee = require 'coffee-script'
  catch err
    coffee = run: {}
  Error.prepareStackTrace = (err, stack) ->
    frames = do ->
      for frame in stack when frame.getFunction() isnt coffee.run
        pos = formatSourcePosition frame, getSourceMapping
        "  at #{pos}"
    "#{err.name}: #{err.message ? ''}\n#{frames.join '\n'}\n"

formatSourcePosition = (frame, getSourceMapping) ->
  fileName = null
  fileLocation = ''
  if frame.isNative()
    fileLocation = "native"
  else
    if frame.isEval()
      fileName = frame.getScriptNameOrSourceURL()
      fileLocation = "#{frame.getEvalOrigin()}, " unless fileName
    else
      fileName = frame.getFileName()
    fileName or= "<anonymous>"
    line = frame.getLineNumber()
    column = frame.getColumnNumber()
    fileLocation = "#{fileName}:#{line}:#{column}"
    if source = getSourceMapping fileName, line, column
      fileLocation += ", <coffee>:#{source[0]}:#{source[1]}"
  functionName = frame.getFunctionName() or "<anonymous>"
  isConstructor = frame.isConstructor()
  isMethodCall = !(frame.isToplevel() || isConstructor)
  if isMethodCall
    methodName = frame.getMethodName()
    typeName = frame.getTypeName()
    if functionName
      tp = as = ''
      if typeName and functionName.indexOf typeName
        tp =  "#{typeName}."
      if methodName and functionName.indexOf(".#{methodName}") isnt functionName.length - methodName.length - 1
        as = " [as #{methodName}]"
        "#{tp}#{functionName}#{as} (#{fileLocation})"
      else
        "#{typeName}.#{methodName or '<anonymous>'} (#{fileLocation})"
  else if isConstructor
    "new #{functionName or '<anonymous>'} (#{fileLocation})"
  else if functionName
    "#{functionName} (#{fileLocation})";
  else
    fileLocation

getSourceMapping = (filename, line, column) ->
  sourceMap = mainModule._sourceMaps[filename]
  return null unless sourceMap
  answer = sourceMap.getSourcePosition [line - 1, column - 1]
  if answer then [answer[0] + 1, answer[1] + 1] else null

loadV3Sourcemaps = (dir) ->
  findAllMaps dir,maps=[]
  maps.forEach (file) ->
    try
      sourceMap = loadV3SourceMap file.map
    catch err
      console.log "load source map error: " + file.map if DEBUG
      console.log err.stack if DEBUG
      return
    mainModule._sourceMaps[file.js] = sourceMap if sourceMap
    console.log "source map loaded: #{file.js}" if DEBUG

findAllMaps = (dir,maps) ->
  items = fs.readdirSync dir
  items.forEach (name) ->
    fullname = path.join dir, name
    try
      stat = fs.statSync(fullname)
    catch err
      return
    if stat.isDirectory()
      findAllMaps fullname, maps
    else if /\.map$/.test name
      jsName = fullname.replace /\.map$/, '.js'
      if fs.existsSync jsName
        maps.push {map:fullname,js:jsName}

loadV3SourceMap = (file) ->
  raw = fs.readFileSync file, 'utf8'
  raw = raw.substring 1 if raw.charCodeAt(0) is 0xFEFF
  v3 = JSON.parse raw
  raw = null
  result = new SourceMap
  option = {noReplace: true}
  lineNo = 0
  lastGeneratedColumn = 0
  lastSourceLine = 0
  lastSourceColumn = 0
  for line in v3.mappings.split ';'
    ++lineNo
    lastGeneratedColumn = 0
    for fragment in line.split ','
      continue unless fragment.length > 0
      [generatedColumn,d] = vlqDecodeValue fragment
      generatedColumn += lastGeneratedColumn

      fragment = fragment[d..]
      [_,d] = vlqDecodeValue fragment # always equal 0 ('A')
      generatedLine = lineNo

      fragment = fragment[d..]
      [sourceLine,d] = vlqDecodeValue fragment
      sourceLine += lastSourceLine

      fragment = fragment[d..]
      [sourceColumn,d] = vlqDecodeValue fragment
      sourceColumn += lastSourceColumn

      result.addMapping [sourceLine,sourceColumn],[generatedLine, generatedColumn],option

      lastGeneratedColumn = generatedColumn
      lastSourceLine = sourceLine
      lastSourceColumn = sourceColumn
  result

exports.patch = (dir=__dirname) ->
  patchStackTrace()
  loadV3Sourcemaps dir
