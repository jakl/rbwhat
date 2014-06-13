# Description
Quickly list review-board requests that need your attention

# Install
* Have a recent [nodejs](http://nodejs.org) : `brew install nodejs`
* Install rbwhat : `npm install -g rbwhat`
* Run once to generate the default config : `rbwhat`
* Edit your config in `~/.rbwhat.json`

# Output
## Structure and Colors
* Review title in bold
* Jira ticket / bug id in white (linkified, clickable in [iTerm](http://iterm2.com))
* Repo / Branch in white (linkified)
* Code review URL underlined (linkified)
* Chronological activity list, begins with initial code submission
  * Green for shipit
  * Red for *DO NOT* shipit
  * Blue for yourself
  * Purple for the original submitter

## Reviews only show if...
* Someone posted a review, and you haven't reviewed their latest update
* You posted a review, and someone responded since your last change
* Old reviews are hidden, default 14 days old, configurable in ~/.rbwhat.json

## Example
```
rbwhat

reviewTitle
  bugURL/bugName
  gitRepoURL/repoName/branchURL/branchName
  https://reviewboard.pwn/r/4242/diff
    submitter       5 days ago
    reviewer        4 days ago
    reviewer        7 hours ago

I will make it win
  go/jira/TEAM-424242
  go/git/coolProject/branch/best_feature_ever
  https://reviewboard.pwn/r/424242/diff a day ago
    bill            an hour ago
    bob             42 minutes ago
    bert            a minute ago
```

## Power Usage
Pass a JSON argument for temporary config overrides:
* Debug
  * `rbwhat '{"debug": true}'`
* Link to review summary, not diff
  * `rbwhat '{"linkDiff": false}'`
* Make the bug a clickable link
  * `rbwhat '{"bugUrl": "url/prefix/for/bug/"}'`
  * No prefix: `rbwhat '{"bugPrefix": ""}'`
* View reviews across all groups
  * `rbwhat '{"filter": {"to-groups": []}}'`
  * The empty array [] is a special wildcard
* See which reviews your coworker is ignoring
  * `rbwhat '{"filter": {"to-user-groups": "coworkerName"}}`
  * Show all incoming reviews for your coworker, instead of yourself
* View all possible [filters here](http://www.reviewboard.org/docs/manual/dev/webapi/2.0/resources/review-request-list/).
* See ~/.rbwhat.json for all config options

# Contributing
Please and thank you for pull requests.

Feel free to edit the js version and I'll port to coffee.

Issues are also welcome.

Many thanks to my teammates for fearless testing and feedback.

This projected is licensed under the terms of the MIT license.
