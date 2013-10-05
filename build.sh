#!/bin/bash -ex
[[ $RUBY ]] || (echo 'please set $RUBY' && exit 1)

rvm get stable
rvm reload

echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/.rvm/user/db

rvm remove $RUBY
rvm install $RUBY --verify-downloads 1
rvm prepare $RUBY

gem install travis-artifacts
travis-artifacts upload --path $RUBY.* --target-path binary
