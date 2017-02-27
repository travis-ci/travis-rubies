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

    get '/usage' do
      Travis::Rubies.meter(:view, 'usage')
      erb :usage
    end

    get '/:os/:os_version/:arch/rubinius-:rbx_version.tar*' do |os, os_version, arch, rbx_version, ext|
      # Redirect rubinius binaries requests to rubini.us
      redirect("http://binaries.rubini.us/#{os}/#{os_version}/#{arch}/rubinius-#{rbx_version}.tar#{ext}")
    end

    get '/:os/:os_version/:arch/:name.tar*' do
      Travis::Rubies.meter(:download, params[:os], params[:os_version])
      Travis::Rubies.meter(:ruby, params[:name])

      if ruby
        Travis::Rubies.meter(:found, params[:name])
        redirect(ruby.url)
      else
        Travis::Rubies.meter(:missing, params[:name])
        not_found("ruby #{params[:name]} not found")
      end
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

@@ usage
<p>This website provides up to date, precompiled, (mostly) statically linked Ruby versions. You can download these directly by choosing the desired version for your operating system from the <a href="/">list of versions</a> for your Operating System.</p>
<p>In addition, it integrates well with different Ruby versioning tools.</p>

<p><h2>Ruby Version Manager (RVM)</h2></p>
<p><a href="https://github.com/wayneeseguin/rvm/releases/tag/1.25.23">RVM 1.25.23</a> or later will automatically try to download binaries (after first trying the RVM server, the JRuby server and then the Rubinius server).</p>
<p>Combine the <code>reinstall</code> command with the <code>--binary</code> flag to keep recompiled Ruby versions up to date:<p>
<p><pre><code>rvm reinstall ruby-head --binary</code></pre></p>
<p>If you have an outdated RVM version, update it by running <code>rvm get stable</code>.</p>

<p><h2>rbenv and chruby</h2></p>
<p>Manually download the appropriate Ruby version and place in the a subdirectory in <code>~/.rbenv/versions</code> or <code>/opt/rubies</code>, respectively.</p>
<p>Alternatively, you can use a Ruby installer to automatically fetch binaries (see below).</p>

<p><h2>ruby-install</h2></p>
<p>After the <a href="https://github.com/postmodern/ruby-install/pull/138">pull request adding binary support</a> has been merged, you can use this feature to download binaries from our server.</p>
<p><pre><code>ruby-install --binary -M https://rubies.travis-ci.org/ ruby 2.1.1</code></pre></p>

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
    <link rel="stylesheet" href="/assets/main.css">
    <link rel="icon" type="image/png" href="https://travis-ci.org/favicon.ico">
    <style>
    .rubies {
      overflow: hidden;
    }
    .os_arch {
      float: left;
      padding: 0 20px;
      width: 250px;
    }
    .os_arch:nth-child(3n+1){
      clear: left;
    }
    .os_arch li * {
      white-space: nowrap;
    }
    </style>
  </head>
  <body>

<div class="wrapper">
  <header class="top">
    <div class="row topbar">
      <h1 id="logo" class="logo">
        <a href="http://travis-ci.org/" title="Travis CI">Travis</a>
      </h1>
      <nav>
        <ul id="navigation" class="navigation">
          <li><a href="/">Travis Rubies</a></li>
          <li><a href="/rubinius">Rubinius</a></li>
          <li><a href="/usage">Usage</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <div id="content" class="row">
    <main id="main" class="main" data-swiftype-index='true'>
      <%= yield %>
    </main>
  </div>

  <footer class="footer">
    <div class="inner row">
      <div class="footer-elem">
        <div class="travis-footer">
          <img alt="The Travis CI logo" src="/assets/footer-logo.svg"></div>
      </div>

      <div class="footer-elem">
        <h3 class="footer-title">&copy;Travis CI, GmbH</h3>
        <address>Rigaer Straße 8<br>10247 Berlin, Germany</address>
        <ul>
          <li><a href="https://docs.travis-ci.com/imprint.html" title="Imprint">Imprint</a></li>
          <li><a href="https://travisci.workable.com/" title="Jobs at Travis CI">Jobs</a></li>
        </ul>
      </div>

      <div class="footer-elem">
        <h3 class="footer-title">Help</h3>
        <ul>
          <li><a href="https://docs.travis-ci.com" title="Travis CI Docs">Documentation</a></li>
          <li><a href="https://blog.travis-ci.com/" title="Travis CI Blog">Blog</a></li>
          <li><a href="mailto:support@travis-ci.com" title="Email Travis CI support">Email</a></li>
          <li><a href="https://twitter.com/travisci" title="Travis CI on Twitter">Twitter</a></li>
        </ul>
      </div>

      <div class="footer-elem">
        <h3 class="footer-title">Travis CI Status</h3>
        <ul>
          <li><div class="status-circle status">Status:</div>
            <a href="http://www.traviscistatus.com/">Travis CI Status</a>
          </li>
        </ul>
      </div>
    </div>
  </footer>
</div>

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script>
$(document).ready(function() {
  $.get('https://pnpcptp8xh9k.statuspage.io/api/v2/status.json').then(function(response) {
    if(response.status && response.status.indicator) {
      $('.status-circle').addClass(response.status.indicator);
    }
  });
});
</script>

  </body>
</html>
