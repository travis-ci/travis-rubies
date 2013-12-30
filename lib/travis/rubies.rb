require 'sinatra/base'
require 'nokogiri'
require 'open-uri'
require 'gh'

module Travis
  class Rubies < Sinatra::Base
    set github_token: ENV.fetch("GITHUB_TOKEN"), slug: 'travis-ci/travis-rubies', signatures: ENV.fetch('TRAVIS_SIGNATURES').split(':')
    set skip_rubies: %w[jruby-head-d20 jruby-head-d21], inline_templates: true

    get '/' do
      doc     = Nokogiri::XML open("https://s3.amazonaws.com/travis-rubies/")
      content = doc.css('Contents').map do |element|
        ruby  = element.css('Key').text[%r{binary/(.*)\.tar}, 1]
        date  = Time.parse(element.css('LastModified').text).to_s
        erb :job, locals: { ruby: ruby, date: date }, layout: false
      end.join
      erb :list, locals: { content: content }
    end

    post '/rebuild/:ruby' do
      check_auth
      time    = Time.now.utc.to_s
      payload = params[:payload] || "no payload"

      branches.each do |branch|
        next unless branch.start_with? params[:ruby]
        write(branch, "last_payload", "time: #{time}\n\npayload:\n#{payload}")
      end

      "OK"
    end

    def check_auth
      return if settings.signatures.include? env['HTTP_AUTHORIZATION']
      logger.warn "untrusted signature: %p" % env['HTTP_AUTHORIZATION']
      halt 403, "requests need to come from Travis CI"
    end

    def write(branch, path, content)
      payload = { message: "Update #{path}", path: path, content: Base64.strict_encode64(content), branch: branch }
      current = gh["repos/#{settings.slug}/contents/#{path}?ref=#{branch}"]
      gh.put("repos/#{settings.slug}/contents/#{path}", payload.merge('sha' => current['sha']))
    rescue GH::Error => error
      raise error unless payload
      gh.put("repos/#{settings.slug}/contents/#{path}", payload)
    end

    def gh
      @gh ||= GH.with(token: settings.github_token)
    end

    def branches
      @branches ||= gh["repos/#{settings.slug}/branches"].map { |b| b["name"] }
    end
  end
end

__END__

@@ layout
<html>
  <head>
    <title>Travis CI: Precompiled Ruby Versions</title>
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/normalize/2.1.3/normalize.min.css">
    <style>
    body { padding: 30px; }
    </style>
  </head>
  <body><%= yield %></body>
</html>

@@ list
<p>These Ruby versions are available on Travis CI in addition to the preinstalled Ruby versions and the Ruby versions with binary builds supplied by RVM and Rubinius. The <i>head</i> versions will be automatically updated.</p>
<%= content %>
<p>As always, the code is <a href="https://github.com/travis-ci/travis-rubies">on GitHub</a>.</p>

@@ job
<p>
  <b><%= ruby %></b><br>
  <small>
    <%= date %>
  </small>
</p>
