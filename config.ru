$:.unshift File.expand_path('lib', __dir__)
File.read('.env').scan(/^(.+)=(.+)$/) { |k, v| ENV[k] = v } if File.exist?('.env')

require 'travis/rubies'
run Travis::Rubies::Web
