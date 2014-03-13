#!/usr/bin/env coffee
require 'colors' # adds color methods on strings
moment = require 'moment'
querystringify = (require 'querystring').stringify # hash to http query
client = new (require 'node-rest-client').Client()
fs = require 'fs'
config = user: 'test', url: 'https://reviewboard.twitter.biz/', group: 'intl-eng-test'

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
    needs_review = config.user isnt submitter # only review others'
    output = formatHeading(submitter, request) # begin output array with heading

    for review in res.reviews
      date = new Date(review.timestamp)
      reviewer = review.links.user.title
      output.push '    ' + colorName(reviewer, submitter, review.ship_it)
      needs_review = needsReview(reviewer, submitter, needs_review, date)

    if needs_review then console.log output.join('\n')

# Review submitter, name, and url heading, as array of lines for output
formatHeading = (submitter, request)->
  url = "#{config.url}r/#{request.id}/diff"
  [
    "#{colorName(submitter, submitter)}: #{request.summary.yellow}"
    "  #{url.underline} #{formatDate request.last_updated}"
  ]

formatDate = (date)->
  moment(new Date(date)).fromNow().cyan

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
  semi_month = new Date()
  semi_month.setDate(semi_month.getDate()-14)

  # if you were last to review then done! (code update / comment / shipit)
  if config.user is reviewer then false
  else if date < semi_month then false
  # code updates are reviews that need your attention
  else if reviewer is submitter then true
  # if someone reviewed your fresh code, check it out
  else if submitter is config.user then true
  # if someone else gives a review, ignore it until there's a response
  else needs_review

main()
