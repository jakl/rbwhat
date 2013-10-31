#!/usr/bin/env coffee
colors = require 'colors'
util = require 'util'
querystring = require 'querystring'
node_rest_client = require 'node-rest-client'
fs = require 'fs'

config_file = process.argv[2]
config_file or= process.env.HOME + '/.rbwhat.json'

config = JSON.parse fs.readFileSync(config_file).toString()
client = new node_rest_client.Client
  user: config.user
  password: config.password

login_user = config.user
rb = config.url

rbcall = (path, args, cb)->
  query = '?' + querystring.stringify args
  client.get rb + path + query, (res)->
    cb JSON.parse(res)

args = 'status': 'pending'
if config.group then args['to-groups'] = config.group

rbcall 'api/review-requests/', args, (res)->
  res.review_requests.forEach eachReviewRequest

eachReviewRequest = (request)->
  submitter = request.links.submitter.title

  rbcall "api/review-requests/#{request.id}/reviews/", null, (res)->
    output = []
    colored_submitter = if submitter is login_user
      submitter.cyan
    else
      submitter.magenta

    output.push colored_submitter + ': ' + request.summary.yellow
    output.push '  ' + "#{rb}r/#{request.id}/diff".underline

    # By default coworker review boards need your attention
    needs_review = if login_user is submitter then false else true

    for review in res.reviews
      reviewer = review.links.user.title
      shipit = review.ship_it

      output.push '    ' + if reviewer is submitter
          reviewer.magenta
        else if shipit
          reviewer.green
        else
          reviewer.red

      if login_user is reviewer
        needs_review = false # if you were last to review then done!
      else if reviewer is submitter
        needs_review = true # if code was updated, do another review

    if needs_review then console.log output.join('\n')
