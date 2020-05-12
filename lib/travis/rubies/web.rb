require 'travis/rubies'
require 'sinatra/base'
require 'rack/cache'

module Travis::Rubies
  module Web
    require 'travis/rubies/web/ui'
    require 'travis/rubies/web/hook'

    Map = Rack::Builder.app do
      use Rack::CommonLogger if ENV['RACK_ENV'] == 'production'
      use Rack::Cache,
        metastore:    'heap:/',
        entitystore:  'heap:/',
        verbose:      true
      use Rack::Static, :urls => ['/assets'], :root => 'public'

      map '/rebuild' do
        run Hook
      end

      map '/' do
        use(Rack::Config) { |e| e['travis.rubies'], e['travis.template'] = List.travis, :travis }
        run(UI)
      end
    end

    def self.call(env)
      Map.call(env)
    end
  end
end
