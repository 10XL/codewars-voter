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
ruby vote.rb --help
Usage: vote [options]
    -u, --user USER                  Your Codewars username
    -t, --token TOKEN                Codewars login token(check README)
    -f, --load PATH_TO_FILE          Path to json file
    -i, --instances INSTANCES        Number of Chrome windows(1-8)
    -g, --get                        Fetch katas without voting
```
## Shortcuts

* Download user info(completed katas, authored katas): `ruby vote.rb -u 10XL -g`
* *Vote using data from file created by above command: `ruby vote.rb -u 10XL -f "user_data/10XL/2017-08-02-07-13-58.json" -i 4`
* *Download/Vote at the same time: `ruby vote.rb -u 10XL -i 8`

_*Store token in 'CODEWARS_TOKEN' environment variable or add `-t "tokenValue"`_

## Notes

Files are saved to `user_data/username/`. Ex: `user_data/10XL/2017-08-02-07-21-58.json`.

You can't vote on your own katas, katas that were deleted, or katas that don't let you delete them. These cause timeout errors since they don't appear in the `code-challenges/authored` endpoint, which is how I'm checking for owned katas. There aren't many of these katas but the ones that timeout get logged to `*_failed.json`. Ex: `user_data/10XL/2017-08-02-07-29-23_failed.json`.
