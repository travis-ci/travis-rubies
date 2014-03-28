require 'travis/rubies'
require 'nokogiri'
require 'open-uri'

module Travis::Rubies
  class List
    PATTERN = %r{binaries/(?<os>.*)/(?<os_version>.*)/(?<arch>.*)/(?<name>.*)\.tar}
    Ruby    = Struct.new(:name, :os, :os_version, :arch, :last_modified)
    OsArch  = Struct.new(:os, :os_version, :arch, :rubies)
    attr_reader :xml

    def initialize(content = open("https://s3.amazonaws.com/travis-rubies/"))
      @xml = Nokogiri::XML(content)
    end

    def rubies
      @xml.css('Contents').map do |element|
        next unless match  = PATTERN.match(element.css('Key').text)
        time = Time.parse(element.css('LastModified').text)
        Ruby.new(match[:name], match[:os], match[:os_version], match[:arch], time)
      end.compact
    end

    def os_archs
      @os_archs ||= rubies.group_by { |r| OsArch.new(r.os, r.os_version, r.arch) }.
        map { |a,r| a.rubies = r.sort_by(&:last_modified).reverse; a }
    end
  end
end
