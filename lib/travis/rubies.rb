require 'metriks'

if email = ENV['LIBRATO_EMAIL'] and token = ENV['LIBRATO_TOKEN']
  require 'metriks/librato_metrics_reporter'
  $stderr.puts 'sending metrics to librato'
  on_error = proc {|ex| $stderr.puts "librato error: #{ex.message} (#{ex.response.body})"}
  Metriks::LibratoMetricsReporter.new(email, token, source: 'travis-rubies', on_error: on_error).start
else
  require 'metriks/reporter/logger'
  $stderr.puts 'sending metrics to stderr'
  Metriks::Reporter::Logger.new(:logger => Logger.new($stderr)).start
end

module Travis
  module Rubies
    autoload :List,   'travis/rubies/list'
    autoload :Update, 'travis/rubies/update'
    autoload :Web,    'travis/rubies/web'

    extend self

    def meter(*args)
      prefix = "rubies"
      args.each do |arg|
        arg = arg.to_s.gsub(/[^A-Za-z0-9\.:\-_]/, '_').gsub(/__+/, '_')
        ::Metriks.meter(prefix << '.' << arg).mark
      end
    end
  end
end