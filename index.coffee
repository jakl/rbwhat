#!/usr/bin/env coffee
rest = require 'rest'
mime = require 'rest/interceptor/mime'
basicAuth = require 'rest/interceptor/basicAuth'
client = rest.chain(mime)
  .chain(basicAuth, username: 'jkoval', password: '4x78k9GtvSMmGX6xhTCf')
client('https://reviewboard.twitter.biz/api/review-requests/?respositroy=170&status=pending&max-results=99999&last-updated-from=2013-09-24')
  .then (res)->
    console.log res.entity
