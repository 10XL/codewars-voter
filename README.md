# codewars-voter
vote on all katas you haven't already
## Requirements
1. Chromedriver installed and added to PATH
2. A Codewars account
3. Token from the Codewars cookie: `remember_user_token`(optional: store in environment variable: `CODEWARS_TOKEN`)
    - Chrome Reference to inspect cookies: https://developers.google.com/web/tools/chrome-devtools/manage-data/cookies
----
## Usage
```ruby
git clone https://github.com/10XL/codewars-voter.git
cd codewars-voter
bundle install
ruby voter.rb
```
