# travis-rubies

The web page you see on `http://rubies.travis-ci.org/` lives on the `web` branch.

It is a sinatra app that you can find in `lib/travis/rubies/web/ui.rb`.

The compiled styles are copied over from the [docs repo](https://github.com/travis-ci/docs-travis-ci-com/).

The `web` branch is deployed as `master` on Heroku. To deploy run

```bash
$ git push heroku web:master
```

This assumes that you have heroku set up as remote.
