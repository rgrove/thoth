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

require 'timeout'
require 'net/flickr'

module Riposte; module Plugin

  # Flickr plugin for Riposte.
  module Flickr
    # Flickr API key. You can either use the default or replace this with your
    # own key.
    API_KEY = '5b1d9919cb2d97585bd3d83e05af80b8'
    
    class << self

      # Gets recent Flickr photos (up to _limit_) for the specified _username_.
      # The return value of this method is cached for 15 minutes to improve
      # performance and to avoid abusing the Flickr API.
      def recent_photos(username, limit = 4)
        @cache ||= {}

        key = "recent_photos_#{username}_#{limit}"
  
        if cached = @cache[key]
          return cached[:value] if cached[:expires] > Time.now
        end

        @flickr ||= Net::Flickr.new(API_KEY)
        
        begin
          Timeout.timeout(5, StandardError) do
            @cache[key] = {
              :expires => Time.now + 900, # expire in 15 minutes
              :value   => @flickr.people.find_by_username(username).
                  photos(:per_page => limit)
            }
          end
        rescue => e
          return []
        else
          @cache[key][:value]
        end
      end

    end
  end

end; end
