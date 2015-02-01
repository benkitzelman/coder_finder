_       = require 'lodash'
async   = require 'async'
request = require 'request'

creds =
  username : null
  password : null

sendRequest = (url, done) ->
  url  = url.replace /^https:\/\/api\.github\.com/, ''
  opts =
    url: "https://#{ creds.username }:#{ creds.password }@api.github.com#{ url }"
    headers:
      'User-Agent' : 'Capt awesomes user agent'

  console.log opts.url
  request.get opts, (err, resp, body) ->
    return done( 'Invalid Github Creds' ) if resp.statusCode is 401
    return done( 'Github Rate Limit Hit') if resp.statusCode is 403 and resp.headers['x-ratelimit-remaining'] is '0'

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

module.exports = (username, password) ->
  creds.username = username
  creds.password = password

  sendRequest   : sendRequest
  get           : get
  buildQueryStr : buildQueryStr
  fetch         : fetch
  fetchAll      : fetchAll
