FROM ruby:2.7.0-slim

LABEL maintainer Travis CI GmbH <support+travis-rubies-docker-images@travis-ci.com>

# packages required for bundle install
RUN ( \
  apt-get update ; \
  apt-get install -y --no-install-recommends git make gcc \
  && rm -rf /var/lib/apt/lists/* \
)

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

RUN ( \
  bundle config set deployment 'true'; \
  bundle config set without 'development test'; \
  bundler install --verbose --retry=3 \
)

COPY . /app

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
