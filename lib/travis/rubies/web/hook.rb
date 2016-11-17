require 'json'

module Travis::Rubies::Web
  class Hook < Sinatra::Base
    post '/:ruby' do
      "OK"
    end

  end
end
