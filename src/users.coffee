_     = require 'lodash'
async = require 'async'

class User

  @fetch = (query, provider, cb) ->
    userSummaries = []
    provider.fetch "/search/users?#{ provider.buildQueryStr query }", userSummaries, (err) ->
      return cb(err) if err

      users = []
      fetchFullUser = (user, cb) ->
        provider.get user.url, (err, attrs) ->
          return cb(err) if err
          users.push( new User(provider, attrs) )
          cb()

      async.eachLimit userSummaries, 20, fetchFullUser, (err) ->
        cb err, users

  constructor: (@provider, attrs) ->
    for k, v of attrs
      Object.defineProperty this, k,
        value         : v
        enumerable    : true
        configurable  : false
        writable      : false

  repositories: (cb) ->
    return cb( null, @_repos ) if @_repos

    @_repos = []
    @provider.fetch @repos_url, @_repos, (err) =>
      cb err, @_repos

module.exports = User

