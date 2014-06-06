#!/usr/bin/env bash

# Tutorial: ./deploy.sh "My commit message"
#   commits all staged and changed files - not untracked/new files

die () {
    echo >&2 "$@"
    exit 1
}

prepend() {
  cat - "$1" > /tmp/chalkboard && mv /tmp/chalkboard "$1"
}

[ "$#" -eq 1 ] || die "Commit message required"

coffee -c rbwhat.coffee
echo '#!/usr/bin/env node' | prepend rbwhat.js
git commit -am "$1"
npm version patch
npm publish
git push origin HEAD
git push origin --tags
