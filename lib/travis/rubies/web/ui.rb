# coding: utf-8
module Travis::Rubies::Web
  class UI < Sinatra::Base
    enable :inline_templates

    before do
      expires ENV['CACHE_TTL']&.to_i || 300, :public, :must_revalidate
    end

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
<header class="m-t-l">
  <p>This website provides up to date, precompiled Ruby versions.
    You can download these directly by choosing the desired version for your operating system from the <a href="/">list of versions</a> for your Operating System.</p>
  <p>Linux archives are statically linked, can be used with different Ruby versioning tools as described below.</p>
  <p>Newer Mac archives are dynamically linked, and may not be usable on all systems. See <a href="https://github.com/travis-ci/travis-rubies/issues/26">travis-ci/travis-rubies#26</a>.</p>
</header>
<section class="m-t-l">
  <h2 class="h2--green">Ruby Version Manager (RVM)</h2>
  <p><a href="https://github.com/wayneeseguin/rvm/releases/tag/1.25.23">RVM 1.25.23</a> or later will automatically try to download binaries (after first trying the RVM server, the JRuby server and then the Rubinius server).</p>
  <p>Combine the <code>reinstall</code> command with the <code>--binary</code> flag to keep recompiled Ruby versions up to date:<p>
    <p><pre><code>rvm reinstall ruby-head --binary</code></pre></p>
    <p>If you have an outdated RVM version, update it by running <code>rvm get stable</code>.</p>
</section>
<section class="m-t-l">
  <h2 class="h2--green">rbenv and chruby</h2>
  <p>Manually download the appropriate Ruby version and place in the a subdirectory in <code>~/.rbenv/versions</code> or <code>/opt/rubies</code>, respectively.</p>
  <p>Alternatively, you can use a Ruby installer to automatically fetch binaries (see below).</p>
</section>
<section class="m-t-l m-b-xl">
  <h2 class="h2--green">ruby-install</h2>
  <p>After the <a href="https://github.com/postmodern/ruby-install/pull/138">pull request adding binary support</a> has been merged, you can use this feature to download binaries from our server.</p>
  <p><pre><code>ruby-install --binary -M https://rubies.travis-ci.org/ ruby 2.1.1</code></pre></p>
</section>
@@ travis
<header class="m-t-l m-b-l">
  <p class="text--medium">These Ruby versions are available on Travis CI in addition to the <a href="http://docs.travis-ci.com/user/languages/ruby/#Supported-Ruby-Versions">preinstalled Ruby versions</a> and the Ruby versions with binary builds <a href="https://rvm.io/binaries/">supplied by RVM</a>, <a href="http://www.jruby.org/download">JRuby</a> and <a href="/rubinius">Rubinius</a>. The <i>head</i> versions will be automatically updated.</p>
</header>
<div class="travis"><%= erb(:list) %></div>
<aside class="m-t-l m-b-xl"><p class="text--medium">As always, the code is <a href="https://github.com/travis-ci/travis-rubies">on GitHub</a>.</p></aside>

@@ rubinius
<header class="m-t-l m-b-l">
  <p class="text--medium">These Ruby versions are available on Travis CI in addition to the <a href="http://docs.travis-ci.com/user/languages/ruby/#Supported-Ruby-Versions">preinstalled Ruby versions</a> and the Ruby versions with binary builds <a href="https://rvm.io/binaries/">supplied by RVM</a>, <a href="http://www.jruby.org/download">JRuby</a> and <a href="/">Travis CI</a>.</p>
</header>
<div class="rubinius"><%= erb(:list) %></div>
<aside class="m-t-l m-b-xl"><p class="text--medium">The <a href="http://rubini.us/">Rubinius</a> team is responsible for compiling and providing these binaries.</p></aside>

@@ ruby
<h2 class="h2--teal"><%= ruby.name %></h2>
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
      <h3 class="h3"><%= format_arch(os_arch) %></h3>
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
    <link rel="stylesheet" href="https://styleguide.travis-ci.com/css/style.css">
    <link rel="icon" type="image/png" href="data:image/png;base64,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">
    <style>
    .rubies {
      display: flex;
      flex-flow: row wrap;
      justify-content: space-between
    }
    </style>
  </head>
  <body>

<div class="layout-wrapper">
  <header class="topbar" role="banner">
    <div class="layout-inner">
      <h1 class="logo">
        <a href="http://travis-ci.org/" title="Travis CI">
          <svg width="100.266px" height="22px" viewBox="0 0 100.266 22" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink">
            <title>Travis CI logo</title>
	    <image xlink:href="https://styleguide.travis-ci.com/images/logos/travis-header-logo.svg" x="0" y="0" width="100.266px" height="22px" />
          </svg>
        </a>
      </h1>
      <nav class="navigation">
        <ul class="navigation-list">
          <li><a class="navigation-anchor" href="/" title="List Travis Rubies">Travis Rubies</a></li>
          <li><a class="navigation-anchor" href="/rubinius" title="List Rubinius">Rubinius</a></li>
          <li><a class="navigation-anchor" href="/usage" title="Usage guide">Usage</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class="layout-main" role="main">
    <div class="layout-inner" data-swiftype-index='true'>
      <%= yield %>
    </div>
  </main>

  <footer class="footer">
    <div class="layout-inner">
      <div class="footer-elem">
        <svg width="142px" height="45.381px" viewBox="0 0 142 45.381" enable-background="new 0 0 142 45.381" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink">
          <title>Travis CI Mascot</title>
          <image xlink:href="https://styleguide.travis-ci.com/images/logos/travis-footer-logo-new.svg" x="0" y="0" width="142px" height="45.381px" />
        </svg>
      </div>

      <div class="footer-elem"></div>

      <div class="footer-elem">
        <h3 class="footer-title">©Travis CI, GmbH</h3>
        <address>Rigaer Straße 8<br>10247 Berlin, Germany</address>
        <ul>
          <li><a href="https://travisci.workable.com/" title="Jobs at Travis CI">Work with Travis CI</a></li>
        </ul>
      </div>

      <div class="footer-elem">
        <h3 class="footer-title">Help</h3>
        <ul>
          <li><a href="https://docs.travis-ci.com" title="Travis CI Docs">Documentation</a></li>
          <li><a href="https://changelog.travis-ci.com/">Changelog</a></li>
          <li><a href="https://blog.travis-ci.com/" title="Travis CI Blog">Blog</a></li>
          <li><a href="mailto:support@travis-ci.com" title="Email Travis CI support">Email</a></li>
          <li><a href="https://twitter.com/travisci" title="Travis CI on Twitter">Twitter</a></li>
        </ul>
      </div>

      <div class="footer-elem">
        <h3 class="footer-title">Legal</h3>
        <ul>
          <li><a href="https://docs.travis-ci.com/imprint.html" title="Imprint">Imprint</a></li>
          <li><a href="https://docs.travis-ci.com/legal/terms-of-service/">Terms of Service</a></li>
          <li><a href="https://docs.travis-ci.com/legal/privacy-policy/">Privacy Policy</a></li>
          <li><a href="https://docs.travis-ci.com/legal/security/">Security Statement</a></li>
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

  <script>
   fetch('https://pnpcptp8xh9k.statuspage.io/api/v2/status.json').then(function(response) {
     return response.json();
   }).then(function(data) {
     if (data.status && data.status.indicator) {
       document.querySelector('.status-circle').classList.add(data.status.indicator);
     }
   });
  </script>
</div>

  </body>
</html>
