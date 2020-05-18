require 'travis/rubies'
require 'nokogiri'
require 'faraday'
require 'aws-sdk-s3'
require 'byebug'

module Travis::Rubies
  class List
    include Enumerable

    FIXNUM_MAX = (2**(0.size * 8 -2) -1)

    def self.travis
      new(bucket: 'travis-rubies', prefix: 'binaries/')
    end

    Ruby    = Struct.new(:slug, :name, :impl, :version, :os, :os_version, :arch, :last_modified, :file_size, :url, :prefix)
    OsArch  = Struct.new(:os, :os_version, :arch, :rubies)
    attr_reader :s3, :bucket, :prefix

    def initialize(bucket:, prefix:'', region: 'us-east-1')
      @s3 = Aws::S3::Client.new(region: region)
      @bucket = bucket
      @prefix = prefix
      @pattern      = %r{#{prefix}(?<slug>(?<os>.*)/(?<os_version>.*)/(?<arch>.*)/(?<name>.*)\.tar\.(?<format>[^\.]+))$}
    end

    def rubies(os_arch: nil)
      if os_arch
        return @rubies.select do |ruby|
          ruby.os == os_arch.os && ruby.os_version == os_arch.os_version && ruby.arch == os_arch.arch
        end
      else
        return @rubies if @rubies
      end
      rubies = []
      is_truncated = true
      response = s3.list_objects_v2(bucket: bucket, prefix: prefix)

      while is_truncated do
        response.contents.each do |obj|
          next unless match = @pattern.match(obj.key)
          time = obj.last_modified
          size = obj.size
          url  = File.join('https://s3.amazonaws.com/', bucket, obj.key)
          impl, version = split_ruby_name(match[:name])
          rubies << Ruby.new(match[:slug], match[:name], impl, version, match[:os], match[:os_version], match[:arch], time, size, url, prefix)
        end

        if is_truncated = response.is_truncated
          response = response.next_page
        end
      end

      @rubies = rubies.compact
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
