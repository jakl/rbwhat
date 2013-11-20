Description
-----------

Quickly list review requests that you need to respond to


Install
-------

Make sure [nodejs](http://nodejs.org) is up to date

`npm install -g jakl/rbwhat`

Create your config in ~/.rbwhat.json

Run `rbwhat`


Output Explained
----------------

Output starts with the submitter's name

It is blue for yourself and purple otherwise

Following is the review name and a link to the review

Next is each review, appropriately color coded

`Green:Shipit  Red:NoShipit  Blue:Yourself  Purple:Submitter`

```
jkoval: make all phrases really pop
  https://reviewboard.twitter.biz/r/234013/diff
    bob
    bob
    jkoval
    bob
    bill
```


~/.rbwhat.json
-----------

```javascript
{
  "user": "your-reviewboard-name",
  "url": "https://reviewboard.twitter.biz/",

  "password": "optional-password",
  "group": "optional-reviewboard-group-filter"
}
```
