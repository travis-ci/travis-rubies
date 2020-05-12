require 'travis/rubies'
require 'nokogiri'
require 'faraday'

module Travis::Rubies
  class List
    include Enumerable

    FIXNUM_MAX = (2**(0.size * 8 -2) -1)

    def self.travis
      new("https://s3.amazonaws.com/travis-rubies/?list-type=2", "binaries/")
    end

    def self.rubinius
      new("http://binaries.rubini.us")
    end

    Ruby    = Struct.new(:slug, :name, :impl, :version, :os, :os_version, :arch, :last_modified, :file_size, :url)
    OsArch  = Struct.new(:os, :os_version, :arch, :rubies)
    attr_reader :xml

    def initialize(content, prefix = "", url = "")
      if content.start_with? 'http'
        uri = URI.parse content
        conn = Faraday.new(uri) do |f|
          f.request :retry, max: 5, retry_statuses: [400]
        end
        resp = conn.get
        if resp.success?
          content, url  = resp.body, content
        end
      end
      @pattern      = %r{#{prefix}(?<slug>(?<os>.*)/(?<os_version>.*)/(?<arch>.*)/(?<name>.*)\.tar\.(?<format>[^\.]+))$}
      @xml          = Nokogiri::XML(content)
      @url          = url
    end

    def rubies
      rubies = []
      is_truncated = true
      while is_truncated do
        @xml.css('Contents').each do |element|
          next unless match  = @pattern.match(element.css('Key').text)
          time = Time.parse(element.css('LastModified').text)
          size = Integer(element.css('Size').text)
          url  = File.join(@url, element.css('Key').text)

          impl, version = split_ruby_name(match[:name])
          rubies << Ruby.new(match[:slug], match[:name], impl, version, match[:os], match[:os_version], match[:arch], time, size, url)
        end

        if @xml.css("IsTruncated").text == 'true'
          continuation_token = @xml.css("NextContinuationToken").text
          puts url = "#{@url}&continuation-token=#{continuation_token}"
          @xml = Nokogiri::XML(Faraday.get(url).body)
        else
          is_truncated = false
        end
      end

      rubies.compact
    end

    def each(&block)
      rubies.each(&block)
    end

    def os_archs
      @os_archs ||= rubies.group_by { |r| OsArch.new(r.os, r.os_version, r.arch) }.
        map do |a,r|
          a.rubies = r.sort do |ruby1, ruby2|
            begin
              if ruby1.impl == ruby2.impl
                Gem::Version.new(ruby1.version) <=> Gem::Version.new(ruby2.version)
              else
                ruby1.impl <=> ruby2.impl
              end
            rescue
              0
            end
          end.reverse
          a
        end
    end

    def vers(str)
      Gem::Version.new str
    rescue
      Gem::Version.new FIXNUM_MAX
    end

    def split_ruby_name(name)
      md = /(?<name>[jm]?ruby|ruby-enterprise|[^-]*)(-(?<version>head|\d+(\.\d+)+))?/.match(name)

      if md[:name] == 'ruby-enterprise'
        name = 'ree'
      else
        name = md[:name]
      end
      [ name, md[:version] ]
    end
  end
end
