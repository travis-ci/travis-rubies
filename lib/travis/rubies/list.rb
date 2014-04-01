require 'travis/rubies'
require 'nokogiri'
require 'open-uri'

module Travis::Rubies
  class List
    def self.travis
      new("https://s3.amazonaws.com/travis-rubies/", "binaries/")
    end

    def self.rubinius
      new("http://binaries.rubini.us")
    end

    Ruby    = Struct.new(:name, :os, :os_version, :arch, :last_modified)
    OsArch  = Struct.new(:os, :os_version, :arch, :rubies)
    attr_reader :xml

    def initialize(content, prefix = "")
      content  = open(content) if content.start_with? 'http'
      @pattern = %r{#{prefix}(?<os>.*)/(?<os_version>.*)/(?<arch>.*)/(?<name>.*)\.tar\.(?<format>[^\.]+)$}
      @xml     = Nokogiri::XML(content)
    end

    def rubies
      @xml.css('Contents').map do |element|
        next unless match  = @pattern.match(element.css('Key').text)
        time = Time.parse(element.css('LastModified').text)
        Ruby.new(match[:name].sub('rubinius', 'rbx'), match[:os], match[:os_version], match[:arch], time)
      end.compact
    end

    def os_archs
      @os_archs ||= rubies.group_by { |r| OsArch.new(r.os, r.os_version, r.arch) }.
        map { |a,r| a.rubies = r.sort_by(&:name).reverse; a }
    end
  end
end
