require 'json'

module Travis::Rubies::Web
  class Hook < Sinatra::Base
    set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')

    before do
      request.body.rewind
      @payload = JSON.parse(params[:payload])
    end

    post '/:ruby' do
      "OK"
    end

  end
end
