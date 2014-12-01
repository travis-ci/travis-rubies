require 'json'

module Travis::Rubies::Web
  class Hook < Sinatra::Base
    set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')

    before do
      request.body.rewind
      @payload = JSON.parse(params[:payload])
    end

    post '/:ruby' do
      check_auth
      Travis::Rubies::Update.build params[:ruby],     commit: @payload["commit"], commit_url: @payload["commit_url"]
      Travis::Rubies::Update.build 'ruby-head-clang', commit: @payload["commit"], commit_url: @payload["commit_url"] if params[:ruby] == 'ruby-head'
      Travis::Rubies.meter(:build, params[:ruby])
      "OK"
    end

    def check_auth
      return if settings.signatures.include? env['HTTP_AUTHORIZATION']
      logger.warn "untrusted signature: %p" % env['HTTP_AUTHORIZATION']
      halt 403, "requests need to come from Travis CI"
    end
  end
end