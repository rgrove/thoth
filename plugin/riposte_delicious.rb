#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
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

module Riposte; module Plugin

  # Del.icio.us plugin for Riposte.
  module Delicious
    FEED_URL = 'http://feeds.delicious.com/feeds/json'
    
    class << self
      
      # Gets recent del.icio.us bookmarks for the specified _username_. The
      # return value of this method is cached for 15 minutes to improve
      # performance and to avoid pounding del.icio.us with excess traffic.
      #
      # Available options:
      #  [+:count+] Number of bookmarks to return (default is 5)
      #  [+:tags+]  Array of tags to filter by. Only bookmarks with the
      #             specified tags will be returned.
      #
      def recent_bookmarks(username, options = {})
        @cache ||= {}
        
        options = {:count => 5}.merge(options)
        request = "#{FEED_URL}/#{CGI.escape(username)}" +
            (options[:tags] ? '/' + CGI.escape(options[:tags].join(' ')) : '') +
            "?raw&count=#{options[:count]}"
        
        if cached = @cache[request]
          return cached[:value] if cached[:expires] > Time.now
        end
        
        r = []

        Timeout.timeout(5, StandardError) do
          r = JSON.parse(open(request).read)
        end
        
        # Parse the response into a more friendly format.
        data = []
        
        r.each do |item|
          data << {
            :url  => item['u'],
            :desc => item['d'],
            :note => item['n'] ? item['n'] : '',
            :tags => item['t'] ? item['t'] : []
          }
        end

        @cache[request] = {
          :expires => Time.now + 900, # expire in 15 minutes
          :value   => data
        }
        
        return data

      rescue => e
        return []
      end
      
    end
  end
  
end; end
