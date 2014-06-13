#!/usr/bin/env node
// Generated by CoffeeScript 1.7.1
(function() {
  var allowedAge, byAge, client, colorName, config, configPath, deprecateKey, extend, formatDate, formatHeading, fs, loadExistingConfig, loadOptions, main, moment, needsReview, outputReviewActivity, pad, printActiveRequest, querystringify, rbapi, rbapiDiffs, rbapiReviewRequests, rbapiReviews, syncConfig, tooOld, user;

  require('colors');

  moment = require('moment');

  extend = require('extend');

  pad = require('pad');

  fs = require('fs');

  querystringify = (require('querystring')).stringify;

  client = new (require('node-rest-client')).Client({
    user: process.env.USER
  });

  configPath = process.env.HOME + '/.rbwhat.json';

  config = {
    url: 'https://reviewboard.twitter.biz/',
    daysOld: 14,
    linkDiff: true,
    bugUrl: 'go/jira/',
    gitUrl: 'cgit.twitter.biz/',
    branchWedge: '/log/?h=',
    filter: {
      status: 'pending',
      'to-groups': 'example-group',
      'to-user-groups': process.env.USER
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
    return rbapiDiffs(request.id, submitter, function(diffs) {
      return rbapiReviews(request.id, function(reviews) {
        return outputReviewActivity(submitter, request, reviews.concat(diffs).sort(byAge));
      });
    });
  };

  byAge = function(a, b) {
    return new Date(a.timestamp) - new Date(b.timestamp);
  };

  outputReviewActivity = function(submitter, request, reviews) {
    var date, output, review, reviewer, show, _i, _len;
    output = formatHeading(submitter, request);
    show = user !== submitter;
    for (_i = 0, _len = reviews.length; _i < _len; _i++) {
      review = reviews[_i];
      date = review.timestamp;
      reviewer = review.links.user.title;
      show = needsReview(reviewer, submitter, show, date);
      output.push('    ' + pad(colorName(reviewer, submitter, review.ship_it), 22) + formatDate(date));
    }
    if (show) {
      return console.log(output.join('\n') + '\n');
    }
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
    repo = (_ref = request.links.repository) != null ? _ref.title : void 0;
    repo = repo ? config.gitUrl.grey + repo.white : 'No Repo'.white;
    branch = (request.branch || 'No Branch').white;
    title = request.summary.bold;
    bug = request.bugs_closed[0];
    bug = bug ? config.bugUrl + bug : 'None';
    bug = 'bug '.grey + pad(bug, 24).white;
    url = ("" + config.url + "r/" + request.id + "/").underline;
    if (config.linkDiff) {
      url += 'diff'.underline;
    }
    return [title, "  " + bug, "  " + repo + config.branchWedge.grey + branch, "  " + url];
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
    var query, url;
    query = '?' + querystringify(args);
    url = config.url + path + query;
    if (config.debug) {
      console.log("curl '" + url + "' | jsonpp | vim -c 'setf javascript' -");
    }
    return client.get(url, function(res) {
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

  rbapiDiffs = function(id, submitter, cb) {
    return rbapi("api/review-requests/" + id + "/diffs/", null, function(res) {
      return cb(res.diffs.map(function(diff) {
        return {
          ship_it: false,
          timestamp: diff.timestamp,
          links: {
            user: {
              title: submitter
            }
          }
        };
      }));
    });
  };

  syncConfig = function() {
    if (fs.existsSync(configPath)) {
      loadExistingConfig();
    }
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    loadOptions();
    if (config.filter['to-groups'] === 'example-group') {
      return console.log('Set options in ~/.rbwhat.json');
    }
  };

  loadExistingConfig = function() {
    var configFile;
    configFile = JSON.parse(fs.readFileSync(configPath).toString());
    extend(true, config, configFile);
    deprecateKey('user', 'to-user-groups', true);
    deprecateKey('group', 'to-groups', true);
    deprecateKey('bugPrefix', 'bugUrl');
    return user = config.filter['to-user-groups'];
  };

  deprecateKey = function(old, fresh, isFilter) {
    var newConfig;
    if (config[old] != null) {
      newConfig = isFilter ? config.filter : config;
      newConfig[fresh] = config[old];
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
