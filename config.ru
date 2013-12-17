require 'sinatra/base'
require 'travis/client'

app = Sinatra.new do
  # Configuration
  enable :logging, :inline_templates
  set :travis, uri: "https://api.travis-ci.org", access_token: ENV.fetch('TRAVIS_TOKEN')

  # repository = Repository.find_by(slug: 'owner/repo')
  # Digest::SHA2.hexdigest(repository.slug + repository.last_build.request.token)
  set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')

  # Travis client
  helpers Travis::Client::Methods
  before { @session = Travis::Client::Session.new(settings.travis) }
  attr_reader :session

  def jobs
    repo('travis-ci/travis-rubies').last_build.jobs
  end

  # list the overview
  get '/' do
    content       = jobs.map do |job|
      ruby        = job.config['env'][/RUBY=(\S+)/, 1]
      description = job.log.body[/\[::RUBY_DESCRIPTION::\](.*)\[::RUBY_DESCRIPTION::\]/, 1]
      erb :job, locals: { job: job, ruby: ruby, description: description }, layout: false
    end.join
    erb :list, locals: { content: content }
  end

  get '/logs/:ruby' do
    pass unless job = jobs.detect { |j| j.config['env'][/RUBY=(\S+)/, 1] == params[:ruby] }
    content_type :txt
    stream do |out|
      job.log.body do |chunk|
        out << chunk
      end
    end
  end

  get '/download/:ruby' do
    compression = params[:ruby].start_with?('jruby') ? 'gz' : 'bz2'
    redirect "https://s3.amazonaws.com/travis-rubies/binary/#{params[:ruby]}.tar.#{compression}"
  end

  # trigger a new job
  post '/rebuild/:ruby' do
    unless settings.signatures.include? env['HTTP_AUTHORIZATION']
      logger.warn "untrusted signature: %p" % env['HTTP_AUTHORIZATION']
      halt 403, "requests need to come from Travis CI"
    end

    jobs.each do |job|
      next unless job.config['env'].include? "RUBY=#{params[:ruby]}"
      logger.info "restarting #%s" % job.number
      restart job
    end

    "ok"
  end
end

run app

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
<p style="color: <%= job.pending? ? "coral" : "dark" + job.color %>">
  <b><%= ruby %>:</b> <%= job.state %><br>
  <small>
    <%= description || "???" %><br>
    <%= job.finished_at || job.started_at || "not yet started" %> &bull;
    <a href="/logs/<%= ruby %>">logs</a> &bull; <a href="/download/<%= ruby %>">download</a>
  </small>
</p>
