_       = require 'lodash'
async   = require 'async'
fs      = require 'fs'
path    = require 'path'
request = require 'request'
GHAuth  = require 'ghauth'

USER_AGENT = 'Capt awesomes user agent'
token      = null

logRequest = (title, content, done) ->
  return done() unless process.env.DEBUG

  outputFilePath = path.join __dirname, '../', "#{Date.now()}_#{title or ''}.json"
  fs.writeFile outputFilePath, content, done

sendRequest = (url, done) ->
  url  = url.replace /^https:\/\/api\.github\.com/, ''
  opts =
    url: "https://api.github.com#{ url }"
    headers:
      'User-Agent'    : USER_AGENT
      'Authorization' : "token #{token}"

  request.get opts, (err, resp, body) ->
    return done( 'Invalid Github Creds' ) if resp.statusCode is 401
    return done( 'Github Rate Limit Hit') if resp.statusCode is 403 and resp.headers['x-ratelimit-remaining'] is '0'

    logRequest 'req', body, (err) ->
      return done( "Err writing file:", err) if err

      done err, resp, ( JSON.parse( body ) if body )

buildQueryStr = (queryObj) ->
  queryStr = "q="
  for k, v of queryObj
    queryStr += if queryStr then '+' else 'q='
    queryStr += "#{k}:#{v}"
  queryStr

get = (url, done) ->
  sendRequest url, (err, resp, data) ->
    done err, data

fetch = (url, results, done) ->
  sendRequest url, (err, resp, body) ->
    return done( err ) if err

    items = if _.isArray(body) then body else body.items
    results.push(items... ) if items

    done null, resp, body

fetchAll = (url, results, done) ->
  results ?= []

  pageNumFromLink = (str) ->
    # i.e. <https://api.github.com/user/repos?page=50&per_page=100>; rel="last"
    return unless num = str.match(/\<.+page=(\d+).*\>/)?[1]
    parseInt num, 10

  addResults = (url, done) ->
    fetch url, results, done

  addResults url, (err, resp) ->
    return done( err ) if err

    nextAndLast = resp.headers?.link?.split(',').map pageNumFromLink
    if not nextAndLast
      return done(null, results) unless nextAndLast

    [next, last] = nextAndLast
    console.log 'pages', next, ' to ', last

    pages = []
    for i in [next..last]
      pages.push "#{url}&page=#{i}"

    async.eachLimit pages, 20, addResults, done

authenticate = (done) ->
  opts =
    configName : 'creds'
    userAgent  : USER_AGENT

  GHAuth opts, (err, creds) ->
    return done( err ) if err

    token = creds.token
    done()

module.exports =
  authenticate  : authenticate
  sendRequest   : sendRequest
  get           : get
  buildQueryStr : buildQueryStr
  fetch         : fetch
  fetchAll      : fetchAll
  USER_AGENT    : USER_AGENT
