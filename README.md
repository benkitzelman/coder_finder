# Coder Finder

Find a developer in any location (i.e. Melbourne) who has at least one repo using a target language(s), ordered by Github score

## Usage

`npm install`

### Miniumum Search

`USER=[my GitHub username] PASS=[my Github password] coffee index.coffee`

Finds all hireable githubbers who have at least one javascript or coffeescript repo

### Search Options

For now, env variables are used to specify params (i.e. similar to USER and PASS)

**LOCATION**  : the city / country name (i.e. `Melbourne`)

**LANGUAGES** : a comma separated lowercase list of languages (i.e. `ruby,python`)

**HIREABLE** : if you want all github users, not just the ones who have set their hireable flag in their profile set to `false`

