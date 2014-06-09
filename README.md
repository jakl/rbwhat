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
* Jira ticket / bug id in white
* Repo / Branch in white
* Code review URL underlined (clickable in [iTerm2](http://iterm2.com))
* Chronological activity list, begins with initial code submission
  * Green for shipit
  * Red for *DO NOT* shipit
  * Blue for yourself
  * Purple for the original submitter

## Reviews only show if...
* Someone posted a review
  * You haven't reviewed their latest code changes
* You posted a review
  * Someone responded after your last change
* The review isn't too many days old
  * Based on config in ~/.rbwhat.json

## Example
```
rbwhat

reviewTitle
  bug TEAM-4242     git repoName / make_my_feature_win
  https://reviewboard.pwn/r/4242/diff 5 days ago
    submitter       5 days ago
    reviewer        4 days ago
    reviewer        7 hours ago

I will make it win
  bug TEAM-424242   git coolProject / best_feature_ever
  https://reviewboard.pwn/r/424242/diff a day ago
    bill            an hour ago
    bob             42 minutes ago
    bert            a minute ago
```

## Power Usage
Pass a JSON argument for temporary config overrides:
* Debug
  * `rbwhat '{"debug": true}'`
* View reviews across all groups
  * `rbwhat '{"filter": {"to-groups": []}}'`
  * The empty array [] is a special wildcard
* Link to review summary, not diff
  * `rbwhat '{"linkDiff": false}'`
* Make the bug a clickable link
  * `rbwhat '{"bugPrefix": "url.prefix/for/bug/"}'`
  * No prefix: `rbwhat '{"bugPrefix": ""}'`
* See which reviews your coworker is ignoring
  * `rbwhat '{"filter": {"to-user-groups": "coworkerName"}}`
  * Show all incoming reviews for your coworker, instead of yourself
* View all possible [filters here](http://www.reviewboard.org/docs/manual/dev/webapi/2.0/resources/review-request-list/).

# Contributing
Please and thank you for pull requests.

Feel free to edit the js version and I'll port to coffee.

Issues are also welcome.

This projected is licensed under the terms of the MIT license.
