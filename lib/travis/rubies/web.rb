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
<html>
  <head>
    <title>Travis CI: Precompiled Ruby Versions</title>
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/normalize/2.1.3/normalize.min.css">
    <style>
    body { padding: 30px; }
    .content {
      overflow: hidden;
    }
    .os_arch {
      float: left;
      padding: 0 20px;
    }
    </style>
  </head>
  <body>
    <p>These Ruby versions are available on Travis CI in addition to the preinstalled Ruby versions and the Ruby versions with binary builds supplied by RVM and Rubinius. The <i>head</i> versions will be automatically updated.</p>
    <div class="content">
      <% @list.os_archs.each do |os_arch| %>
        <div class="os_arch">
          <b><%= format_arch(os_arch) %></b>
          <ul>
            <% os_arch.rubies.each do |ruby| %>
              <li><b><%= ruby.name %></b> (<%= ruby.last_modified %>)</li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    <p>As always, the code is <a href="https://github.com/travis-ci/travis-rubies">on GitHub</a>.</p>
  </body>
</html>