#!/usr/bin/env node
// Generated by CoffeeScript 1.7.1
(function() {
  var allowedAge, client, colorName, config, configPath, deprecateKey, extend, formatDate, formatHeading, fs, loadExistingConfig, loadOptions, main, moment, needsReview, pad, printActiveRequest, querystringify, rbapi, rbapiReviewRequests, rbapiReviews, syncConfig, tooOld, user;

  require('colors');

  moment = require('moment');

  extend = require('extend');

  pad = require('pad');

  querystringify = (require('querystring')).stringify;

  client = new (require('node-rest-client')).Client();

  fs = require('fs');

  configPath = process.env.HOME + '/.rbwhat.json';

  config = {
    url: 'https://reviewboard.twitter.biz/',
    daysOld: 14,
    linkDiff: true,
    filter: {
      status: 'pending',
      'to-groups': 'intl-eng-test',
      'to-user-groups': 'test'
    }
  };

  user = config.filter['to-user-groups'];

  main = function() {
    syncConfig();
    return rbapiReviewRequests(config.filter, printActiveRequest);
  };

  printActiveRequest = function(request) {
    var submitter;
    submitter = request.links.submitter.title;
    return rbapiReviews(request.id, function(reviews) {
      var date, output, review, reviewer, show, _i, _len;
      show = user !== submitter && !tooOld(request.time_added);
      output = formatHeading(submitter, request);
      for (_i = 0, _len = reviews.length; _i < _len; _i++) {
        review = reviews[_i];
        date = review.timestamp;
        reviewer = review.links.user.title;
        show = needsReview(reviewer, submitter, show, date);
        output.push('    ' + pad(colorName(reviewer, submitter, review.ship_it), 22) + formatDate(date));
      }
      if (show) {
        return console.log(output.join('\n'));
      }
    });
  };

  needsReview = function(reviewer, submitter, show, date) {
    if (user === reviewer) {
      return false;
    } else if (tooOld(date)) {
      return false;
    } else if (reviewer === submitter) {
      return true;
    } else if (submitter === user) {
      return true;
    } else {
      return show;
    }
  };

  formatHeading = function(submitter, request) {
    var branch, bug, repo, title, url, _ref;
    title = request.summary.bold;
    repo = ((_ref = request.links.repository) != null ? _ref.title : void 0) || 'No Repo';
    bug = 'bug '.grey + pad(request.bugs_closed[0] || 'None', 15).white;
    branch = 'branch '.grey + (request.branch || 'None').white;
    url = ("" + config.url + "r/" + request.id + "/").underline;
    if (config.linkDiff) {
      url += 'diff'.underline;
    }
    return ["" + (pad(colorName(submitter, submitter), 18)) + " " + repo.white + " " + title, "  " + bug + branch, "  " + url + " " + (formatDate(request.time_added))];
  };

  formatDate = function(date) {
    return moment(new Date(date)).fromNow().cyan;
  };

  tooOld = function(date) {
    return new Date(date) < allowedAge();
  };

  allowedAge = function() {
    var date;
    date = new Date();
    date.setDate(date.getDate() - config.daysOld);
    return date;
  };

  colorName = function(name, submitter, shipit) {
    switch (name) {
      case user:
        return name.cyan;
      case submitter:
        return name.magenta;
      default:
        if (shipit) {
          return name.green;
        } else {
          return name.red;
        }
    }
  };

  rbapi = function(path, args, cb) {
    var query;
    query = '?' + querystringify(args);
    if (config.debug) {
      console.log("curl '" + (config.url + path + query) + "' | jsonpp");
    }
    return client.get(config.url + path + query, function(res) {
      return cb(JSON.parse(res));
    });
  };

  rbapiReviewRequests = function(filter, cb) {
    return rbapi('api/review-requests/', filter, function(res) {
      return res.review_requests.forEach(cb);
    });
  };

  rbapiReviews = function(id, cb) {
    return rbapi("api/review-requests/" + id + "/reviews/", null, function(res) {
      return cb(res.reviews);
    });
  };

  syncConfig = function() {
    if (fs.existsSync(configPath)) {
      loadExistingConfig();
    }
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    loadOptions();
    if (user === 'test') {
      return console.log('Set options in ~/.rbwhat.json');
    }
  };

  loadExistingConfig = function() {
    var configFile;
    configFile = JSON.parse(fs.readFileSync(configPath).toString());
    extend(true, config, configFile);
    deprecateKey('user', 'to-user-groups');
    deprecateKey('group', 'to-groups');
    return user = config.filter['to-user-groups'];
  };

  deprecateKey = function(old, fresh) {
    if (config[old] != null) {
      config.filter[fresh] = config[old];
      return delete config[old];
    }
  };

  loadOptions = function() {
    var firstCliArgument;
    if (firstCliArgument = process.argv[2]) {
      return extend(true, config, JSON.parse(firstCliArgument));
    }
  };

  main();

}).call(this);
