#!/usr/bin/env coffee
require 'colors' # adds color methods on strings
moment = require 'moment'
extend = require 'extend'
pad    = require 'pad'
fs     = require 'fs'
querystringify = (require 'querystring').stringify # hash to http query
client = new (require 'node-rest-client').Client user: process.env.USER

configPath = process.env.HOME + '/.rbwhat.json'
config = # All valid config keys with example values
  url: 'https://reviewboard.twitter.biz/'
  daysOld: 14
  linkDiff: true
  bugPrefix: 'go/jira/'
  filter:
    status: 'pending'
    'to-groups': 'example-group'
    'to-user-groups': process.env.USER
user = config.filter['to-user-groups'] # easy to type alias

# Peruse review requests, printing active ones
main = ->
  syncConfig() # Sync config file, writing defaults for unset values
  rbapiReviewRequests config.filter, printActiveRequest

# Print each review request that needs attention
printActiveRequest = (request)->
  submitter = request.links.submitter.title

  rbapiDiffs request.id, submitter, (diffs)->
    rbapiReviews request.id, (reviews)->
      # Merge-sort diffs and reviews by their age and output as activity list
      outputReviewActivity submitter, request, reviews.concat(diffs).sort byAge

byAge = (a, b)-> new Date(a.timestamp) - new Date(b.timestamp)

outputReviewActivity = (submitter, request, reviews)->
  output = formatHeading(submitter, request) # seed output with heading
  # Review requests started by a coworker initially need your attention
  show = user isnt submitter
  for review in reviews
    date = review.timestamp
    reviewer = review.links.user.title
    show = needsReview(reviewer, submitter, show, date) # should we review?
    output.push '    ' +
      pad(colorName(reviewer, submitter, review.ship_it), 22) +
      formatDate(date)
  console.log output.join('\n') + '\n' if show

# Rules for marking a review board as needing attention
#   called on each review chronologically
needsReview = (reviewer, submitter, show, date)->
  # if you were last to review then done! (code update / comment / shipit)
  if user is reviewer then false
  # if the review is ancient (default 14 days ago) then done!
  else if tooOld date then false
  # code updates are reviews that need your attention
  else if reviewer is submitter then true
  # if someone reviewed your fresh code, check it out
  else if submitter is user then true
  # if someone else gives a review, ignore it until there's a response
  else show

# Request's submitter, name, and url, as an array of lines for output heading
formatHeading = (submitter, request)->
  repo   = 'git '.grey
  repo  += (request.links.repository?.title or 'No Repo').white
  branch = (request.branch or 'No Branch').white
  title  = request.summary.bold
  bug    = request.bugs_closed[0]
  bug    = if bug then config.bugPrefix + bug else 'None'
  bug    = 'bug '.grey + pad(bug, 24).white
  url    = "#{config.url}r/#{request.id}/".underline
  url   += 'diff'.underline if config.linkDiff
  [
    title
    "  #{bug} #{repo} #{'/'.grey} #{branch}"
    "  #{url}"
  ]

# Date colouring and ageing  <- So British!
formatDate = (date)-> moment(new Date(date)).fromNow().cyan
tooOld = (date)-> new Date(date) < allowedAge()
allowedAge = ->
  date = new Date()
  date.setDate(date.getDate() - config.daysOld)
  date

# Rules for coloring a reviewer's name
colorName = (name, submitter, shipit)->
  switch name
    when user then name.cyan
    when submitter then name.magenta
    else
      if shipit then name.green else name.red

# Calls rb api with a hash of query params. Returns response as hash
rbapi = (path, args, cb)->
  query = '?' + querystringify args
  url = config.url + path + query
  if config.debug
    console.log "curl '#{url}' | jsonpp | vim -c 'setf javascript' -"
  client.get url, (res)-> cb JSON.parse(res)

# Get all the review-requests, given a filter
rbapiReviewRequests = (filter, cb)->
  rbapi 'api/review-requests/', filter, (res)->
    res.review_requests.forEach(cb)

# Get all the reviews for a request
rbapiReviews = (id, cb)->
  rbapi "api/review-requests/#{id}/reviews/", null, (res)-> cb(res.reviews)

# In a request, find all the "Review request changed" entries
rbapiDiffs = (id, submitter, cb)->
  rbapi "api/review-requests/#{id}/diffs/", null,
    (res)-> cb res.diffs.map (diff)-> # use the same data model as a review
      ship_it: false
      timestamp: diff.timestamp
      links: user: title: submitter

# Load config in this priority: bash arg, ~/.rbwhat.json, defaults
syncConfig = ->
  loadExistingConfig() if fs.existsSync(configPath)
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2))
  loadOptions()
  if config.filter['to-groups'] is 'example-group'
    console.log 'Set options in ~/.rbwhat.json'

# Load values from ~/.rbwhat.json
loadExistingConfig = ->
  configFile = JSON.parse fs.readFileSync(configPath).toString()
  extend(true, config, configFile)
  deprecateKey('user', 'to-user-groups')
  deprecateKey('group', 'to-groups')
  user = config.filter['to-user-groups'] # user variable that's easier to type

# delete the old key and stash its value into the new key
deprecateKey = (old, fresh)->
  if config[old]?
    config.filter[fresh] = config[old]
    delete config[old]

# Load the first argument as a top priority JSON config
loadOptions = ->
  if firstCliArgument = process.argv[2]
    extend(true, config, JSON.parse firstCliArgument)

main()
