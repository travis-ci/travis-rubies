#!/bin/bash -e
source ./build_info.sh
[[ $RUBY ]] || { echo 'please set $RUBY' && exit 1; }
echo "EVERYBODY STAND BACK, WE'RE INSTALLING $RUBY"

if [ `expr $RUBY : '.*-clang$'` -gt 0 ]; then
  export CC=${RUBY##*-}
fi

source ~/.bashrc
unset DYLD_LIBRARY_PATH

# speed up git clone
export rvm_git_clone_depth=1

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

travis_rvm_os_path() {
  if which sw_vers >> /dev/null; then
    echo "osx/$(sw_vers -productVersion | cut -d. -f1,2)/$(uname -m)"
  else
    echo "$(lsb_release -i -s | tr '[:upper:]' '[:lower:]')/$(lsb_release -r -s)/$(uname -m)"
  fi
}

fold_start() {
  echo -e "travis_fold:start:$1\033[33;1m$2\033[0m"
}

fold_end() {
  echo -e "\ntravis_fold:end:$1\r"
}

#######################################################
# update rvm
fold_start rvm.1 "update rvm"
rvm remove 1.8.7
rvm get head
rvm reload
rvm cleanup all
fold_end rvm.1

#######################################################
# get rid of binary meta data
fold_start rvm.2 "clean up meta data"
echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/user/db || true
fold_end rvm.2

#######################################################
# install smf etc
if which sw_vers >> /dev/null; then
  fold_start rvm.3 "OSX specific setup"
  curl -L https://get.smf.sh | sh
  export PATH="${PATH}:/Users/travis/.sm/bin:/Users/travis/.sm/pkg/active/bin:/Users/travis/.sm/pkg/active/sbin"
  rvm autolibs smf
  sudo mkdir -p /etc/openssl
  sudo chown -R $USER: /etc/openssl
  rvm use 1.9.3
  mkdir -p $rvm_path/patchsets/ruby
  echo "" > $rvm_path/patchsets/ruby/osx_static
  fold_end rvm.3
fi

#######################################################
# build the binary
fold_start build "build $RUBY"
rvm alias delete $RUBY
rvm remove $RUBY

case $RUBY in
ruby-1.8*)  rvm install $RUBY --verify-downloads 1 --disable-install-doc --with-gcc=gcc;;
ruby-*)     rvm install $RUBY --verify-downloads 1 --movable --disable-install-doc --with-gcc=gcc;;
*)          rvm install $RUBY --verify-downloads 1 --disable-install-doc --with-gcc=gcc;;
esac

rvm prepare $RUBY
fold_end build

#######################################################
# make sure bundler works
fold_start check.1 "make sure bundler works"
echo "source 'https://rubygems.org'; gem 'rails'" > Gemfile
travis_retry rvm $RUBY do gem install bundler
travis_retry rvm $RUBY do bundle install
fold_end check.1

#######################################################
# publish to bucket
fold_start publish "upload to S3"
if [[ $TRAVIS_PULL_REQUEST == 'false' ]]; then
  gem install faraday -v 0.8.9
  gem install travis-artifacts
  travis-artifacts upload --path $RUBY.* --target-path binaries/$(travis_rvm_os_path)
else
  echo "This is a Pull Request, not publishing."
fi
fold_end publish

#######################################################
# make sure it installs
fold_start check.2 "make sure it installs"
rvm remove $RUBY
echo "rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
rvm_remote_server_type3=rubies
rvm_remote_server_verify_downloads3=1" > $rvm_path/user/db
cat $rvm_path/user/db
rvm install $RUBY --binary
fold_end check.2

