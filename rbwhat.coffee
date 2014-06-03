#!/usr/bin/env coffee
require 'colors' # adds color methods on strings
moment = require 'moment'
querystringify = (require 'querystring').stringify # hash to http query
client = new (require 'node-rest-client').Client()
fs = require 'fs'

configPath = process.env.HOME + '/.rbwhat.json'
config = {}
configDefaults = # All valid config keys with example values
  user: 'test'
  url: 'https://reviewboard.twitter.biz/'
  daysOld: 14
  filter:
    status: 'pending'
    'to-groups': 'intl-eng-test'

# Peruse review requests, printing active ones
main = ->
  syncConfig() # Sync config file, writing defaults for unset values
  rbapiReviewRequests config.filter, printActiveRequest

# Print each review request that needs attention
printActiveRequest = (request)->
  submitter = request.links.submitter.title
  rbapiReviews request.id, (reviews)->
    # Boards started by you or boards that are too old, don't need review
    #   unless responses to the board meet other criteria in needsReview()
    needs_review = config.user isnt submitter and not tooOld request.time_added

    output = formatHeading(submitter, request) # begin output array with heading

    for review in reviews
      date = review.timestamp
      reviewer = review.links.user.title
      needs_review = needsReview(reviewer, submitter, needs_review, date)

      output.push '    ' + colorName(reviewer, submitter, review.ship_it) +
        ' ' + formatDate date

    if needs_review then console.log output.join('\n')

# Rules for marking a review board as needing attention
#   called on each review chronologically
needsReview = (reviewer, submitter, needs_review, date)->
  # if you were last to review then done! (code update / comment / shipit)
  if config.user is reviewer then false
  # if the review is ancient (default 14 days ago) then done!
  else if tooOld date then false
  # code updates are reviews that need your attention
  else if reviewer is submitter then true
  # if someone reviewed your fresh code, check it out
  else if submitter is config.user then true
  # if someone else gives a review, ignore it until there's a response
  else needs_review

# Review submitter, name, and url heading, as array of lines for output
formatHeading = (submitter, request)->
  url = "#{config.url}r/#{request.id}/diff"
  [
    "#{colorName(submitter, submitter)}: #{request.summary.yellow}"
    "  #{url.underline} #{formatDate request.time_added}"
  ]

formatDate = (date)-> moment(new Date(date)).fromNow().cyan
tooOld = (date)-> new Date(date) < allowedAge()
allowedAge = ->
  date = new Date()
  date.setDate(date.getDate() - config.daysOld)
  date

# Rules for coloring a reviewer's name
colorName = (name, submitter, shipit)->
  switch name
    when config.user then name.cyan
    when submitter then name.magenta
    else
      if shipit then name.green else name.red

# Calls rb api with a hash of query params. Returns response as hash
rbapi = (path, args, cb)->
  query = '?' + querystringify args
  client.get config.url + path + query, (res)->
    cb JSON.parse(res)

rbapiReviewRequests = (filter, cb)->
  rbapi 'api/review-requests/', filter, (res)-> res.review_requests.forEach(cb)

rbapiReviews = (id, cb)->
  rbapi "api/review-requests/#{id}/reviews/", null, (res)-> cb(res.reviews)

syncConfig = ->
  loadExistingConfig() if fs.existsSync(configPath)
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2))
  if config.user is 'test' then console.log 'Set options in ~/.rbwhat.json'

loadExistingConfig = ->
  config = JSON.parse fs.readFileSync(configPath).toString()
  mergeUnsetKeys(config, configDefaults)
  if config.group? # deprecated config key
    config.filter['to-groups'] = config.group
    delete config.group

mergeUnsetKeys = (child, template)->
  child.__proto__ = template
  child[key] = child[key] for key in Object.keys(template)

main()
