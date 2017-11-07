# travis-rubies

The web page you see on `http://rubies.travis-ci.org/` lives on the `web` branch.

It is a sinatra app that you can find in `lib/travis/rubies/web/ui.rb`.

You can start it locally with `$ bundle exec rackup -s puma -p $PORT`.

This app imports the live Styleguide styles.

The `web` branch is deployed as `master` on Heroku. To deploy run

```bash
$ git push heroku web:master
```

This assumes that you have heroku set up as remote.
