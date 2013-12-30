$:.unshift File.expand_path('lib', __dir__)

require 'travis/rubies'
run Travis::Rubies
