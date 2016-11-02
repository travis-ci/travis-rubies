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
      payload = JSON.parse(request.body.read.fetch('payload',''))
      signature = request.env["HTTP_SIGNATURE"]

      pkey = OpenSSL::PKey::RSA.new(public_key)

      if pkey.verify(
          OpenSSL::Digest::SHA1.new,
          Base64.decode64(signature),
          payload.to_json
      )
        status 200
        "Signature verification succeeded"
      else
        status 403
        "Signature verification failed; requests must come from Travis CI"
      end
    rescue
      status 500
      "Exception encountered while verifying signature"
    end

    def public_key
      conn = Faraday.new(:url => API_HOST) do |faraday|
        faraday.adapter Faraday.default_adapter
      end

      response = conn.get '/config'
      JSON.parse(response.body)["config"]["notifications"]["webhook"]["public_key"]
    rescue
      ''
    end
  end
end
