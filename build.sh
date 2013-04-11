#!/bin/bash -ex
[[ $RUBY ]] || (echo 'please set $RUBY' && exit 1)

rvm get stable
rvm reload

rvm remove $RUBY
rvm install $RUBY
rvm prepare $RUBY

gem install travis-artifacts
travis-artifacts upload --path $RUBY.* --target-path binary
