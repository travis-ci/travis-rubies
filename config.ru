require 'sinatra/base'
require 'travis/client'

app = Sinatra.new do
  # Configuration
  enable :logging
  set :travis, uri: 'https://api.travis-ci.com/', access_token: ENV.fetch('TRAVIS_TOKEN')
  set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')

  # Travis client
  helpers Travis::Client::Methods
  before { @session = Travis::Client::Session.new(settings.travis) }
  attr_reader :session

  # Check authenticity
  before do
    next if settings.signatures.include? env['HTTP_AUTHORIZATION']
    halt 403, "requests need to come from Travis CI"
  end

  post '/rebuild/:ruby' do
    repo('travis-pro/travis-rubies').last_build.jobs.each do |job|
      next unless job.config['env'].include? "RUBY=#{params[:ruby]}"
      logger.info "restarting #%s" % job.number
      restart job
    end

    "ok"
  end
end

run app