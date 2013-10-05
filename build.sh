#!/bin/bash -ex
[[ $RUBY ]] || (echo 'please set $RUBY' && exit 1)

rvm get stable
rvm reload

echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/.rvm/user/db || true

rvm remove $RUBY
rvm install $RUBY --verify-downloads 1
rvm prepare $RUBY

# make sure bundler works
rvm use $RUBY
gem install bundler
bundle install

rvm use default
gem install travis-artifacts
travis-artifacts upload --path $RUBY.* --target-path binary
