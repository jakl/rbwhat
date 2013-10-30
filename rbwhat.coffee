#!/usr/bin/env coffee
colors = require 'colors'
util = require 'util'
querystring = require 'querystring'
node_rest_client = require 'node-rest-client'
fs = require 'fs'

client_args = JSON.parse fs.readFileSync(process.argv[2]).toString()
client = new node_rest_client.Client(client_args)

login_user = client_args.user
rb = 'https://reviewboard.twitter.biz/'

rbcall = (path, args, cb)->
  query = '?' + querystring.stringify args
  client.get rb + path + query, (res)->
    cb JSON.parse(res)

args =
  'status': 'pending'
  'to-groups': 'intl-eng'

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
