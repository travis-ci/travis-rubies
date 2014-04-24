require 'metriks'

if email = ENV['LIBRATO_EMAIL'] and token = ENV['LIBRATO_TOKEN']
  require 'metriks/librato_metrics_reporter'
  Metriks::LibratoMetricsReporter.new(email, token, source: 'travis-rubies').start
else
  require 'metriks/reporter/logger'
  Metriks::Reporter::Logger.new(:logger => Logger.new($stderr)).start
end

module Travis
  module Rubies
    autoload :List,   'travis/rubies/list'
    autoload :Update, 'travis/rubies/update'
    autoload :Web,    'travis/rubies/web'

    extend self

    def meter(*args)
      name = args.map { |a| a.to_s.gsub(/[^A-Za-z0-9.:\-_]/, '_').gsub(/__+/, '_') }.reject(&:empty?).join('.')
      ::Metriks.meter("rubies.#{name}").mark
    end
  end
end