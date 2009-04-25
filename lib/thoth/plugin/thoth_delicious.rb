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

require 'cgi'
require 'json'
require 'open-uri'
require 'timeout'

module Thoth; module Plugin

  # Del.icio.us plugin for Thoth.
  module Delicious
    FEED_URL = 'http://feeds.delicious.com/feeds/json'

    Configuration.for("thoth_#{Thoth.trait[:mode]}") do
      delicious {

        # Time in seconds to cache results. It's a good idea to keep this nice
        # and high both to improve the performance of your site and to avoid
        # pounding on del.icio.us's servers. Default is 900 seconds (15
        # minutes).
        cache_ttl 900 unless Send('respond_to?', :cache_ttl)

        # Request timeout in seconds.
        request_timeout 5 unless Send('respond_to?', :request_timeout)

      }
    end

    class << self

      # Gets recent del.icio.us bookmarks for the specified _username_. The
      # return value of this method is cached to improve performance and to
      # avoid pounding del.icio.us with excess traffic.
      #
      # Available options:
      # [<tt>:count</tt>] Number of bookmarks to return (default is 5)
      # [<tt>:tags</tt>]  Array of tags to filter by. Only bookmarks with the
      #                   specified tags will be returned.
      #
      def recent_bookmarks(username, options = {})
        cache   = Ramaze::Cache.plugin
        options = {:count => 5}.merge(options)
        request = "#{FEED_URL}/#{::CGI.escape(username)}" <<
            (options[:tags] ? '/' << ::CGI.escape(options[:tags].join(' ')) : '') <<
            "?raw&count=#{options[:count]}"

        if value = cache[request]
          return value
        end

        response = []

        Timeout.timeout(Config.delicious['request_timeout'], StandardError) do
          response = JSON.parse(open(request).read)
        end

        # Parse the response into a more friendly format.
        data = []

        response.each do |item|
          data << {
            :url  => item['u'],
            :desc => item['d'],
            :note => item['n'] ? item['n'] : '',
            :tags => item['t'] ? item['t'] : []
          }
        end

        return cache.store(request, data, :ttl => Config.delicious['cache_ttl'])

      rescue => e
        Ramaze::Log.error "Thoth::Plugin::Delicious: #{e.message}"
        return []
      end

    end
  end

end; end
