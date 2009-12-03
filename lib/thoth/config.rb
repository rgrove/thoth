#--
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

module Thoth

  module Config; class << self

    # Adds the specified config Hash to Thoth's config lookup chain. Any
    # configuration values in _config_ will be used as defaults unless they're
    # specified earlier in the lookup chain (i.e. in Thoth's config file).
    def <<(config)
      raise ArgumentError, "config must be a Hash" unless config.is_a?(Hash)

      (@lookup ||= []) << config
      cache_config

      @lookup
    end

    # Loads the specified configuration file.
    def load(file)
      raise Thoth::Error, "Config file not found: #{file}" unless File.file?(file)

      @live = {
        'db' => "sqlite:///#{HOME_DIR}/db/live.db",

        'site' => {
          'name' => "New Thoth Blog",
          'desc' => "Thoth is awesome.",
          'url'  => "http://localhost:7000/",

          'core_js'  => [
            'http://yui.yahooapis.com/2.8.0/build/yahoo-dom-event/yahoo-dom-event.js',
            '/js/thoth.js'
          ],

          'css' => [],
          'js'  => [],

          'enable_comments' => true,
          'enable_sitemap'  => true,

          'gravatar' => {
            'enabled' => true,
            'default' => "identicon",
            'rating'  => "g",
            'size'    => 32
          }
        },

        'admin' => {
          'name'  => "John Doe",
          'email' => "",
          'user'  => "thoth",
          'pass'  => "thoth",
          'seed'  => "6d552ac197a862b82b85868d6c245feb"
        },

        'plugins' => [],

        'media' => File.join(HOME_DIR, 'media'),

        'server' => {
          'adapter'       => 'webrick',
          'address'       => '0.0.0.0',
          'port'          => 7000,
          'enable_cache'  => true,
          'enable_minify' => true,
          'error_log'     => File.join(HOME_DIR, 'log', 'error.log'),

          'memcache' => {
            'enabled' => false,
            'servers' => ['localhost:11211:1']
          }
        },

        'timestamp' => {
          'long'  => "%A %B %d, %Y @ %I:%M %p (%Z)",
          'short' => "%Y-%m-%d %I:%M"
        }
      }

      @dev = {
        'db' => "sqlite:///#{HOME_DIR}/db/dev.db",

        'server' => {
          'enable_cache'  => false,
          'enable_minify' => false
        }
      }

      begin
        config = YAML.load(Erubis::Eruby.new(File.read(file)).result(binding)) || {}
      rescue => e
        raise Thoth::ConfigError, "Config error in #{file}: #{e}"
      end

      @lookup ||= if Thoth.trait[:mode] == :production
          [config['live'] || {}, @live]
      else
        [config['dev'] || {}, config['live'] || {}, @dev, @live]
      end

      cache_config
    end

    def method_missing(name)
      (@cached || {})[name.to_s] || {}
    end

    private

    # Merges configs such that those earlier in the lookup chain override those
    # later in the chain.
    def cache_config
      @cached = {}

      @lookup.reverse.each do |c|
        c.each {|k, v| @cached[k] = config_merge(@cached[k] || {}, v) }
      end
    end

    def config_merge(master, value)
      if value.is_a?(Hash)
        value.each {|k, v| master[k] = config_merge(master[k] || {}, v) }
        return master
      end

      value
    end

  end; end
end
