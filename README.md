# travis-rubies

The web page you see on `http://rubies.travis-ci.org/` lives on the `web` branch.

It is a sinatra app that you can find in `lib/travis/rubies/web/ui.rb`.

The compiled styles are copied over from the [docs repo](https://github.com/travis-ci/docs-travis-ci-com/).

## Deployment

To deploy travis-rubies, use the `#deploys` channel:

```
.deploy travis-rubies to staging
.deploy travis-rubies to production
```

## Build

You are looking at the `master` branch. The code for building rubies can be found on the [build](https://github.com/travis-ci/travis-rubies/tree/build) branch.
