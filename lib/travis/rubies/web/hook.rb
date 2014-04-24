module Travis::Rubies::Web
  class Hook < Sinatra::Base
    set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')

    post '/:ruby' do
      check_auth
      Travis::Rubies::Update.build params[:ruby]
      Travis::Rubies::Update.build 'ruby-head-clang' if params[:ruby] == 'ruby-head'
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