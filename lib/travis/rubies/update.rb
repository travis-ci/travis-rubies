require 'travis/rubies'
require 'shellwords'
require 'gh'

module Travis::Rubies
  class Update
    def self.build(ruby, options = {})
      new(options).build(ruby)
    end

    def initialize(options = {})
      @github_token = options[:github_token] || ENV.fetch("GITHUB_TOKEN")
      @branch       = options[:branch]       || 'build'
      @slug         = options[:slug]         || 'travis-ci/travis-rubies'
    end

    def build(ruby)
      content = "export RUBY=%s\n" % Shellwords.escape(ruby)
      message = "trigger new build for %s" % ruby
      write("build_info.sh", content, message)
    end

    def write(path, content, message)
      gh      = GH.with(token: @github_token)
      payload = { message: message, path: path, content: Base64.strict_encode64(content), branch: @branch }
      current = gh["repos/#{@slug}/contents/#{path}?ref=#{@branch}"]
      gh.put("repos/#{@slug}/contents/#{path}", payload.merge('sha' => current['sha']))
    rescue GH::Error => error
      raise error unless payload
      gh.put("repos/#{@slug}/contents/#{path}", payload)
    end
  end
end
