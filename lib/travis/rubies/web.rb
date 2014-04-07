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

# require 'travis/rubies'
# require 'sinatra/base'
# 
# module Travis::Rubies
#   class Web < Sinatra::Base
#     set :signatures, ENV.fetch('TRAVIS_SIGNATURES').split(':')
#     enable :inline_templates
# 
#     before do
#       redirect 'http://rubies.travis-ci.org' if request.ssl? and request.get?
#     end
# 
#     get '/' do
#       @list = List.travis
#       erb :travis
#     end
# 
#     get '/rubinius' do
#       @list = List.rubinius
#       erb :rubinius
#     end
# 
#     post '/rebuild/:ruby' do
#       check_auth
#       Update.build params[:ruby]
#       Update.build 'ruby-head-clang' if params[:ruby] == 'ruby-head'
#       "OK"
#     end
# 
#     def check_auth
#       return if settings.signatures.include? env['HTTP_AUTHORIZATION']
#       logger.warn "untrusted signature: %p" % env['HTTP_AUTHORIZATION']
#       halt 403, "requests need to come from Travis CI"
#     end
# 
#     def format_arch(os_arch)
#       name = os_arch.os == 'osx' ? "Mac OS X" : os_arch.os.capitalize
#       "#{name} #{os_arch.os_version}"
#     end
#   end
# end
# 
