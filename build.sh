#!/usr/bin/env bash

announce() {
  travis_time_start
  echo \$ $@
  $@
  travis_time_finish
}

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
  elif which freebsd-version >> /dev/null; then
    echo "freebsd/$(freebsd-version | cut -d- -f1)/x86_64"
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

function install_awscli() {
  if which sw_vers >> /dev/null; then
    announce brew install awscli
  elif which freebsd-version >> /dev/null; then
    announce sudo pkg install -y awscli
  else
    command -v pip >/dev/null || (curl -sSO https://bootstrap.pypa.io/get-pip.py && python get-pip.py --user)
    pip install --user --upgrade pip
    announce pip install --user awscli
  fi
}

function update_mvn() {
  VERSION=$1
  fold_start mvn.1 "update mvn to $VERSION"
  curl -sSO http://mirrors.ibiblio.org/apache/maven/maven-3/${VERSION}/binaries/apache-maven-${VERSION}-bin.tar.gz
  tar xzf apache-maven-$VERSION-bin.tar.gz
  export PATH=$PWD/apache-maven-$VERSION/bin:$PATH
  export M2_HOME=$PWD/apache-maven-$VERSION
  mvn -version
  fold_end mvn.1
}

travis_time_start() {
  travis_timer_id=$(printf %08x $(( RANDOM * RANDOM )))
  travis_start_time=$(travis_nanoseconds)
  echo -en "travis_time:start:$travis_timer_id\r${ANSI_CLEAR}"
}

travis_time_finish() {
  local result=$?
  travis_end_time=$(travis_nanoseconds)
  local duration=$(($travis_end_time-$travis_start_time))
  echo -en "\ntravis_time:end:$travis_timer_id:start=$travis_start_time,finish=$travis_end_time,duration=$duration\r${ANSI_CLEAR}"
  return $result
}

function travis_nanoseconds() {
  local cmd="date"
  local format="+%s%N"
  local os=$(uname)

  if hash gdate > /dev/null 2>&1; then
    cmd="gdate" # use gdate if available
  elif [[ "$os" = Darwin ]]; then
    format="+%s000000000" # fallback to second precision on darwin (does not support %N)
  fi

  $cmd -u $format
}

function ensure_gpg_key() {
  local key_id="409B6B1796C275462A1703113804BB82D39DC0E3"
  local gpg_cmd="gpg"

  if command -v gpg2; then
    gpg_cmd="gpg2"
  fi

  if ! command -v $gpg_cmd; then
    if command -v sw_vers; then
      env HOMEBREW_NO_AUTO_UPDATE=1 brew install $gpg_cmd
    elif which freebsd-version >> /dev/null; then
      sudo pkg install -y $gpg_cmd
    else
      sudo apt-get install $gpg_cmd
    fi
  fi

  $gpg_cmd --list-keys $key_id || $gpg_cmd --keyserver hkp://keys.gnupg.net --recv-keys $key_id
  curl -sSL https://rvm.io/mpapis.asc | $gpg_cmd --import -
}

function install_autoconf() {
  pushd /tmp
  wget http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz
  tar xvf autoconf-latest.tar.gz
  pushd autoconf-*
  ./configure
  make up
  make && sudo make install
  popd
  popd
}

PATH=$HOME/bin:$HOME/.local/bin:$PATH

#######################################################
# update rvm
fold_start rvm.1 "update rvm"
announce rvm remove 1.8.7
ensure_gpg_key
rm -f ~/.rvmrc
announce rvm get head --auto-dotfiles
announce rvm reload
announce rvm use 2.3
announce rvm cleanup all
fold_end rvm.1

#######################################################
# get rid of binary meta data
fold_start rvm.2 "clean up meta data"
echo -n > $rvm_path/user/md5
echo -n > $rvm_path/user/sha512
echo -n > $rvm_path/user/db || true
echo "done"
fold_end rvm.2

#######################################################
# prepare env
fold_start rvm.3 "set up env for rvm"
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  announce source "$HOME/.rvm/scripts/rvm"
fi
announce unset DYLD_LIBRARY_PATH
announce export rvm_git_clone_depth=1 # speed up git clone
fold_end rvm.3

#######################################################
# install smf etc
if which sw_vers >> /dev/null; then
  announce install_autoconf
  fold_start rvm.4 "OSX specific setup"
  announce rvm autolibs homebrew
  announce rvm use --install 2.4
  announce sudo mkdir -p /etc/openssl
  announce sudo chown -R $USER: /etc/openssl
  # announce rvm use 2.0.0 --fuzzy
  announce mkdir -p $rvm_path/patchsets/ruby
  echo '$ echo "" > $rvm_path/patchsets/ruby/osx_static'
  echo "" > $rvm_path/patchsets/ruby/osx_static
  fold_end rvm.4
elif which freebsd-version >> /dev/null; then
  fold_start rvm.4 "FreeBSD specific setup"
  fold_end rvm.4
else
  fold_start rvm.4 "Linux specific setup"
  MOVABLE_FLAG="--movable"
  announce sudo apt-get update
  announce sudo apt-get install libssl1.0.0 openssl
  fold_end rvm.4
fi

#######################################################
# check $RUBY
fold_start ruby "check which ruby to build"
if [ -z $RUBY ]; then
  announce source ./build_info.sh
fi
[[ $RUBY ]] || { echo 'please set $RUBY' && exit 1; }
export RUBY=$(rvm strings $RUBY)
announce export RUBY=${RUBY//[[:blank:]]/}
echo "EVERYBODY STAND BACK, WE'RE INSTALLING $RUBY"
announce unset CC
if [ `expr $RUBY : '.*-clang$'` -gt 0 ]; then
  announce export CC=${RUBY##*-}
fi
fold_end ruby

#######################################################
# build the binary
fold_start build "build $RUBY"
announce rvm alias delete $RUBY
announce rvm remove $RUBY

case $RUBY in
mruby*)
  announce export SKIP_CHECK=1
  if which apt-get >> /dev/null; then
    announce sudo apt-get -q install gperf
  fi
  announce rvm install $RUBY --verify-downloads 1;;
ruby-1.*)
  if which sw_vers >> /dev/null; then
    echo "not building $RUBY on OSX, can't statically compile it"
    exit
  elif which freebsd-version >> /dev/null; then
    echo "not building $RUBY on FreeBSD, can't statically compile it"
    exit
  else
    announce rvm install $RUBY --verify-downloads 1 $MOVABLE_FLAG --disable-install-doc
  fi;;
ruby-*)
  announce rvm install $RUBY $EXTRA_FLAGS --verify-downloads 1 $MOVABLE_FLAG --disable-install-doc -C --without-tcl,--without-tk,--without-gmp
  ;;
jruby-head)
  update_mvn 3.3.9
  announce rvm install $RUBY --verify-downloads 1;;
*)      announce rvm install $RUBY --verify-downloads 1;;
esac

announce rvm prepare $RUBY
fold_end build

#######################################################
# make sure bundler works
fold_start check.1 "make sure bundler works"
if [ -n "${SKIP_CHECK}" ]; then
  echo '$SKIP_CHECK is set, skipping bundler check'
else
  echo "source 'https://rubygems.org'; gem 'sinatra'" > Gemfile
  announce travis_retry rvm $RUBY do gem install bundler
  announce travis_retry rvm $RUBY do bundle install
fi
fold_end check.1

# make sure ffi works
if [[ $RUBY != jruby* ]]; then
  fold_start check.2 "make sure native extension can be built"
  if [ -n "${SKIP_CHECK}" ]; then
    echo '$SKIP_CHECK is set, skipping ffi check'
  else
    echo "source 'https://rubygems.org'; gem 'sinatra'" > Gemfile
    announce travis_retry rvm $RUBY do gem install ffi
    announce travis_retry rvm $RUBY do gem uninstall -x ffi
  fi
  fold_end check.2
fi

#######################################################
# publish to bucket
fold_start publish "upload to S3"
if [[ $TRAVIS_PULL_REQUEST == 'false' ]]; then
  mkdir -p $HOME/bin
  PATH=$HOME/bin:$HOME/.local/bin:$PATH

  for f in $RUBY.*; do
    base=${f%%.*}
    openssl dgst -sha512 -out ${base}.sha512.txt $f
  done

  command -v aws || install_awscli
  for f in $RUBY.*; do
    aws s3 cp $f s3://travis-rubies/binaries/$(travis_rvm_os_path)/ --acl=public-read
  done
else
  echo "This is a Pull Request, not publishing."
fi
fold_end publish

#######################################################
# make sure it installs
fold_start check.3 "make sure it installs"
if [[ $TRAVIS_PULL_REQUEST == 'false' ]]; then
  announce rvm remove $RUBY
  echo "rvm_remote_server_url3=https://s3.amazonaws.com/travis-rubies/binaries
  rvm_remote_server_type3=rubies
  rvm_remote_server_verify_downloads3=1" > $rvm_path/user/db
  announce cat $rvm_path/user/db
  announce travis_retry rvm install $RUBY --binary
  announce gem env
  announce bundle env
else
  echo "This is a Pull Request, skipping."
fi
fold_end check.3
