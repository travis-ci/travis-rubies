module Travis::Rubies::Web
  class UI < Sinatra::Base
    enable :inline_templates

    get '/' do
      Travis::Rubies.meter(:view, :index)
      redirect 'http://rubies.travis-ci.org' if request.ssl?
      erb env['travis.template']
    end

    get '/index.txt' do
      Travis::Rubies.meter(:view, 'index.txt')
      content_type :txt
      rubies.map { |r| url(r.slug) }.join("\n")
    end

    get '/:os/:os_version/:arch/:name.tar*' do
      Travis::Rubies.meter(:download, params[:os], params[:os_version], params[:arch], params[:name])
      not_found("ruby #{params[:name]} not found") unless ruby
      redirect(ruby.url)
    end

    get '/:os/:os_version/:arch/:name' do
      Travis::Rubies.meter(:view, params[:os], params[:os_version], params[:arch], params[:name])
      not_found(erb("<p>Ruby version not found! :(</p>")) unless ruby
      erb :ruby
    end

    def ruby
      @ruby ||= rubies.detect do |ruby|
        ruby.os         == params[:os]          and
        ruby.os_version == params[:os_version]  and
        ruby.arch       == params[:arch]        and
        ruby.name       == params[:name]
      end
    end

    def rubies
      env['travis.rubies']
    end

    def format_arch(os_arch)
      name = os_arch.os == 'osx' ? "Mac OS X" : os_arch.os.capitalize
      "#{name} #{os_arch.os_version}"
    end

    def format_size(input)
      format = "B"
      iec    = %w[KiB MiB GiB TiB PiB EiB ZiB YiB]
      while input > 512 and iec.any?
        input /= 1024.0
        format = iec.shift
      end
      input = input.round(2) if input.is_a? Float
      "#{input} #{format}"
    end
  end
end

__END__

@@ travis
<p>These Ruby versions are available on Travis CI in addition to the <a href="http://docs.travis-ci.com/user/languages/ruby/#Supported-Ruby-Versions">preinstalled Ruby versions</a> and the Ruby versions with binary builds <a href="https://rvm.io/binaries/">supplied by RVM</a>, <a href="http://www.jruby.org/download">JRuby</a> and <a href="/rubinius">Rubinius</a>. The <i>head</i> versions will be automatically updated.</p>
<div class="travis"><%= erb(:list) %></div>
<p>As always, the code is <a href="https://github.com/travis-ci/travis-rubies">on GitHub</a>.</p>

@@ rubinius
<p>These Ruby versions are available on Travis CI in addition to the <a href="http://docs.travis-ci.com/user/languages/ruby/#Supported-Ruby-Versions">preinstalled Ruby versions</a> and the Ruby versions with binary builds <a href="https://rvm.io/binaries/">supplied by RVM</a>, <a href="http://www.jruby.org/download">JRuby</a> and <a href="/">Travis CI</a>.</p>
<div class="rubinius"><%= erb(:list) %></div>
<p>The <a href="http://rubini.us/">Rubinius</a> team is responsible for compiling and providing these binaries.</p>

@@ ruby
<p><h2><%= ruby.name %></h2></p>
<p>
  <%= format_size(ruby.file_size) %>, <%= ruby.last_modified %><br>
  <%= format_arch(ruby) %>, <%= ruby.arch %>
</p>
<p>
  <form action="<%= url(ruby.slug) %>">
    <input type="submit" value="Download">
  </form>
</p>

@@ list
<div class="rubies">
  <% rubies.os_archs.each do |os_arch| %>
    <div class="os_arch">
      <h3><%= format_arch(os_arch) %></h3>
      <ul>
        <% os_arch.rubies.each do |ruby| %>
          <li><a href="<%= url("#{ruby.os}/#{ruby.os_version}/#{ruby.arch}/#{ruby.name}") %>"><%= ruby.name %></a></li>
        <% end %>
      </ul>
    </div>
  <% end %>
</div>

@@ layout

<html>
  <head>
    <title>Travis CI: Precompiled Ruby Versions</title>
    <link rel="stylesheet" href="http://docs.travis-ci.com/style.css">
    <link href='http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,800' rel='stylesheet' type='text/css'>
    <link rel="icon" type="image/png" href="https://travis-ci.org/favicon.ico">
    <style>
    .rubies {
      overflow: hidden;
    }
    .os_arch {
      float: left;
      padding: 0 20px;
    }
    .travis .os_arch {
      width: 250px;
    }
    .rubinius .os_arch {
      width: 150px;
    }
    .os_arch li * {
      white-space: nowrap;
    }
    #content {
      min-height: 70vh;
    }
    </style>
  </head>
  <body>
    <div id="navigation">
      <div class="wrapper">
        <a href="/" class="logo-home"><img src="http://docs.travis-ci.com/images/travisci-small.png" alt="Travis Logo"></a>
        <ul>
          <li><a href="/">Travis Rubies</a></li>
          <li><a href="/rubinius">Rubinius</a></li>
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