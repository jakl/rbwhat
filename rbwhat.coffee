#!/usr/bin/env coffee
require 'colors' # adds color methods on strings
moment = require 'moment'
querystringify = (require 'querystring').stringify # hash to http query
client = new (require 'node-rest-client').Client()
fs = require 'fs'
config =
  user: 'test'
  url: 'https://reviewboard.twitter.biz/'
  group: 'intl-eng-test'
  daysOld: 14

# Peruse review requests, printing active ones
main = ->
  loadConfigOrDefault()
  filter = status: 'pending', 'to-groups': config.group
  rbapi 'api/review-requests/', filter, (res)->
    res.review_requests.forEach printActiveRequest

# Write template of config file if one doesn't exist
loadConfigOrDefault = ->
  config_path = process.env.HOME + '/.rbwhat.json'
  if fs.existsSync config_path
    config = JSON.parse fs.readFileSync(config_path).toString()
    unless config.daysOld
      config.dasyOld = 14
      console.log 'Add this to the top of ~/.rbwhat.json
                   \n  "daysOld": 14,
                   \nYou can now limit reviews to a certain age in days.
                   \nDefaulting to 14 now...'
    config.allowedAge = new Date()
    config.allowedAge.setDate(config.allowedAge.getDate() - config.daysOld)
  else
    fs.writeFileSync config_path, JSON.stringify(config, null, 2)

  if config.user is 'test' then console.log 'Set options in ~/.rbwhat.json'

# Calls rb api with a hash of query params. Returns response as hash
rbapi = (path, args, cb)->
  query = '?' + querystringify args
  client.get config.url + path + query, (res)->
    cb JSON.parse(res)

# Print each review request that needs attention
printActiveRequest = (request)->
  submitter = request.links.submitter.title

  rbapi "api/review-requests/#{request.id}/reviews/", null, (res)->
    # Boards started by you or boards that are too old, don't need review
    #   unless responses to the board meet other criteria in needsReview()
    needs_review = config.user isnt submitter and not tooOld request.time_added

    output = formatHeading(submitter, request) # begin output array with heading

    for review in res.reviews
      date = review.timestamp
      reviewer = review.links.user.title
      needs_review = needsReview(reviewer, submitter, needs_review, date)

      output.push '    ' + colorName(reviewer, submitter, review.ship_it) +
        ' ' + formatDate date

    if needs_review then console.log output.join('\n')

# Review submitter, name, and url heading, as array of lines for output
formatHeading = (submitter, request)->
  url = "#{config.url}r/#{request.id}/diff"
  [
    "#{colorName(submitter, submitter)}: #{request.summary.yellow}"
    "  #{url.underline} #{formatDate request.time_added}"
  ]

formatDate = (date)-> moment(new Date(date)).fromNow().cyan
tooOld = (date)-> new Date(date) < config.allowedAge

# Rules for coloring a reviewer's name
colorName = (name, submitter, shipit)->
  switch name
    when config.user then name.cyan
    when submitter then name.magenta
    else
      if shipit then name.green else name.red

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

main()
