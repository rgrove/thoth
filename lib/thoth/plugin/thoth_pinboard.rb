#--
# Copyright (c) 2010 Ryan Grove <ryan@wonko.com>
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

  # Pinboard plugin for Thoth.
  module Pinboard
    FEED_URL = 'http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20rss%20where%20url%3D%22http%3A%2F%2Ffeeds.pinboard.in%2Frss%2Fu%3A{username}%22%20limit%20{limit}&format=json'

    Config << {
      'pinboard' => {

        # Time in seconds to cache results.
        'cache_ttl' => 900,

        # Request timeout in seconds.
        'request_timeout' => 5

      }
    }

    class << self

      # Gets recent Pinboard bookmarks for the specified _username_. The
      # return value of this method is cached to improve performance.
      #
      # Available options:
      # [<tt>:count</tt>] Number of bookmarks to return (default is 5)
      #
      def recent_bookmarks(username, options = {})
        cache   = Ramaze::Cache.plugin
        options = {:count => 5}.merge(options)
        request = FEED_URL.gsub('{username}', ::CGI.escape(username)).
                    gsub('{limit}', options[:count].to_s)

        if value = cache[request]
          return value
        end

        response = []

        Timeout.timeout(Config.pinboard['request_timeout'], StandardError) do
          response = JSON.parse(open(request).read)
        end

        # Parse the response into a more friendly format.
        data = []

        response['query']['results']['item'].each do |item|
          data << {
            :url   => item['link'],
            :title => item['title'].strip,
            :note  => (item['description'] || '').strip,
            :tags  => (item['subject'] || '').strip.split(' ')
          }
        end

        return cache.store(request, data, :ttl => Config.pinboard['cache_ttl'])

      rescue => e
        Ramaze::Log.error "Thoth::Plugin::Pinboard: #{e.message}"
        return []
      end

    end
  end

end; end
