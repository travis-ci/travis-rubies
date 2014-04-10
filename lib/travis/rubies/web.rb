require 'travis/rubies'
require 'sinatra/base'

module Travis::Rubies
  module Web
    require 'travis/rubies/web/ui'
    require 'travis/rubies/web/hook'

    Map = Rack::Builder.app do
      map '/rebuild' do
        run Hook
      end

      map '/' do
        use(Rack::Config) { |e| e['travis.rubies'], e['travis.template'] = List.travis, :travis }
        run(UI)
      end

      map '/rubinius' do
        use(Rack::Config) { |e| e['travis.rubies'], e['travis.template'] = List.rubinius, :rubinius }
        run(UI)
      end
    end

    def self.call(env)
      Map.call(env)
    end
  end
end
