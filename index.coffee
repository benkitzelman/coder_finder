_       = require 'lodash'
async   = require 'async'
request = require 'request'
Github  = require './src/github'
users   = require './src/users'

creds =
  username : process.env.USER
  password : process.env.PASS

query =
  location        : 'melbourne'
  targetLanguages : ['javascript', 'coffeescript']
  onlyHireable    : true

github = Github creds.username, creds.password

users.fetch location: query.location, github, (err, users) ->
  return console.log('ERR', err)       if err
  return console.log('No Users Found') if _.isEmpty(users)
  
  targetUsers      = if query.onlyHireable then _.select( users, hireable: true ) else users
  loadAllUserRepos = _.map targetUsers, (u) -> u.repositories.bind(u)
  
  async.parallelLimit loadAllUserRepos, 20, (err) ->
    return console.log('ERR', err) if err

    usersWithTargetLangs = _.select targetUsers, (u) ->
      u._repos = _.reject u._repos, (r) -> not _.include( query.targetLanguages, r.language?.toLowerCase() )
      not _.isEmpty u._repos

    console.log JSON.stringify(usersWithTargetLangs, null, 4)
