_       = require 'lodash'
async   = require 'async'
request = require 'request'

sendRequest = (url, cb) ->
  username = process.env.USER
  password = process.env.PASS

  opts =
    url: 'https://' + username + ':' + password + '@api.github.com' + url
    headers:
      'User-Agent' : 'Capt awesomes user agent'

  request.get opts, (err, response, body) ->
    cb err, response, ( JSON.parse( body ) if body )


fetchAll = (url, results, done) ->
  results ?= []

  pageNumFromLink = (str) -> 
    # <https://api.github.com/user/repos?page=50&per_page=100>; rel="last"
    return unless num = str.match(/\<.+page=(\d+).*\>/)?[1]
    parseInt num, 10

  getResults = (url, cb) ->
    sendRequest url, (err, resp, body) ->
      return cb( err ) if err
      results.push body.items...
      cb(null, resp)

  getResults url, (err, resp) ->
    return cb( err ) if err

    console.log 'link: ',resp.headers?.link
    nextAndLast = resp.headers?.link?.split(',').map pageNumFromLink
    if not nextAndLast
      console.log resp.body
      return done(null, users) unless nextAndLast

    [next, last] = nextAndLast

    pages = []
    for i in [next..last]
      pages.push "#{url}&page=#{i}"

    async.eachLimit pages, 20, getResults, done

fetchUsers = (query, users, cb) ->

  buildQueryStr = ->
    queryStr = "q="
    for k, v of query
      queryStr += if queryStr then '+' else 'q='
      queryStr += "#{k}:#{v}"
    queryStr

  fetchAll "/search/users?#{ buildQueryStr() }", users, cb

users = []
fetchUsers location: 'melbourne', users, (err) ->
  console.log('ERR', err) if err
  console.log JSON.stringify(users, null, 4)
