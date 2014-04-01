require 'travis/rubies'
require 'sinatra/base'

module Travis::Rubies
  class Web < Sinatra::Base
    set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')
    enable :inline_templates

    get '/' do
      @list = List.new
      erb :list
    end

    post '/rebuild/:ruby' do
      check_auth
      Update.build params[:ruby]
      Update.build 'ruby-head-clang' if params[:ruby] == 'ruby-head'
      "OK"
    end

    def check_auth
      return if settings.signatures.include? env['HTTP_AUTHORIZATION']
      logger.warn "untrusted signature: %p" % env['HTTP_AUTHORIZATION']
      halt 403, "requests need to come from Travis CI"
    end

    def format_arch(os_arch)
      name = os_arch.os == 'osx' ? "Mac OS X" : os_arch.os.capitalize
      "#{name} #{os_arch.os_version}"
    end
  end
end

__END__

@@ list
<p>These Ruby versions are available on Travis CI in addition to the <a href="http://docs.travis-ci.com/user/languages/ruby/#Supported-Ruby-Versions">preinstalled Ruby versions</a> and the Ruby versions with binary builds <a href="https://rvm.io/binaries/">supplied by RVM</a>, JRuby and Rubinius. The <i>head</i> versions will be automatically updated.</p>
<div class="rubies">
  <% @list.os_archs.each do |os_arch| %>
    <div class="os_arch">
      <h3><%= format_arch(os_arch) %></h3>
      <ul>
        <% os_arch.rubies.each do |ruby| %>
          <li><%= ruby.name %></li>
        <% end %>
      </ul>
    </div>
  <% end %>
</div>
<p>As always, the code is <a href="https://github.com/travis-ci/travis-rubies">on GitHub</a>.</p>

@@ layout

<html>
  <head>
    <title>Travis CI: Precompiled Ruby Versions</title>
    <link rel="stylesheet" href="http://docs.travis-ci.com/style.css">
    <link href='http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,800' rel='stylesheet' type='text/css'>
    <style>
    .rubies {
      overflow: hidden;
    }
    .os_arch {
      float: left;
      padding: 0 20px;
      width: 250px;
    }
    .os_arch li * {
      white-space: nowrap;
    }
    </style>
  </head>
  <body>
    <div id="navigation">
      <div class="wrapper">
        <a href="http://travis-ci.org/" class="logo-home"><img src="http://docs.travis-ci.com/images/travisci-small.png" alt="Travis Logo"></a>
        <ul>
          <li><a href="http://blog.travis-ci.com">Blog</a></li>
          <li><a href="http://docs.travis-ci.com">Documentation</a></li>
        </ul>
      </div>
    </div>

    <div id="content">
      <div class="wrapper">
        <div class="pad">
          <%= yield %>
        </div>
      </div>
    </div>

    <footer>
      <div class="wrapper">
        <div class="large-6 columns left">
          <div id="travis-logo">
            <img src="http://docs.travis-ci.com/images/travis-mascot-200px.png" id="travis-mascot">
          </div>
          <div id="travis-address">
            <p>&copy; 2014 Travis CI GmbH,<br> Prinzessinnenstr. 20, 10969 Berlin, Germany</p>
          </div>
        </div>

        <div class="large-6 columns right">
          <div id="footer-nav">
            <ul class="left">
              <li><a href="mailto:contact@travis-ci.com">Email</a></li>
              <li><a href="http://chat.travis-ci.com">Live Chat</a></li>
              <li><a href="http://docs.travis-ci.com">Docs</a></li>
              <li><a href="http://status.travis-ci.com">Status</a></li>
            </ul>
          </div>
          <div id="berlin-sticker">
            <img src="http://docs.travis-ci.com/images/made-in-berlin-badge.png" id="made-in-berlin">
          </div>
        </div>
      </div>
    </footer>
  </body>
</html>