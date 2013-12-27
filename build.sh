#!/bin/bash -ex
[[ $RUBY ]] || {[[ $TRAVIS_BRANCH ]] && RUBY=$TRAVIS_BRANCH}
[[ $RUBY ]] || {echo 'please set $RUBY' && exit 1}
echo "EVERYBODY STAND BACK, WE'RE INSTALLING $RUBY"

source ~/.bashrc

travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n\033[33;1mThe command \"$@\" failed. Retrying, $count of 3.\033[0m\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
    echo "\n\033[33;1mThe command \"$@\" failed 3 times.\033[0m\n" >&2
  }

  return $result
}

#######################################################
# update rvm
rvm get stable
rvm reload

#######################################################
# get rid of binary meta data
echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/user/db || true

#######################################################
# build the binary
rvm alias delete $RUBY
rvm remove $RUBY
rvm install $RUBY --verify-downloads 1
rvm prepare $RUBY

#######################################################
# make sure bundler works
travis_retry rvm $RUBY do gem install bundler
travis_retry rvm $RUBY do bundle install

#######################################################
# publish to bucket
gem install travis-artifacts
travis-artifacts upload --path $RUBY.* --target-path binary

#######################################################
# make sure it installs
rvm remove $RUBY
echo "rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies
rvm_remote_server_path3=binary
rvm_remote_server_verify_downloads3=1" > $rvm_path/user/db
rvm install $RUBY --binary

#######################################################
# print out ruby version
rvm $RUBY do ruby -e 'puts "[::RUBY_""DESCRIPTION::]#{RUBY_DESCRIPTION}[::RUBY_""DESCRIPTION::]"'
