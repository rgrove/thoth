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
  class SearchController < Ramaze::Controller
    map       '/search'
    layout    '/layout'
    view_root File.join(Config.theme.view, 'search'),
              File.join(VIEW_DIR, 'search')

    helper :admin, :cache, :ysearch

    if Config.server.enable_cache
      cache :index, :ttl => 300, :key => lambda {
        auth_key_valid?.to_s + request[:q] + (request[:start] || '') +
            (request[:count] || '')
      }
    end

    def index
      redirect_referrer if request[:q].nil? || request[:q].empty?
      @query = request[:q].strip
      redirect_referrer if @query.empty?

      count  = request[:count] ? request[:count].strip.to_i : 10
      start  = request[:start] ? request[:start].strip.to_i : 1

      count = 5   if count < 5
      count = 100 if count > 100
      start = 1   if start < 1
      start = 990 if start > 990

      @title = "Search results for #{@query}"

      @data = yahoo_search(
        "#{@query} -inurl:/tag -inurl:/archive -inurl:/search",
        :adult_ok => 1,
        :results  => count,
        :site     => Config.site.url.gsub(/^https?:\/\/([^\/]+)\/?$/i){$1},
        :start    => start
      )

      # Set up pagination links.
      if @data[:available] > @data[:returned]
        if @data[:start] > 1
          prev_start = start - count
          prev_start = 1 if prev_start < 1

          @prev_url = "#{Rs()}?q=#{u(@query)}&count=#{count}&start=" <<
              prev_start.to_s
        end

        if @data[:available] > (@data[:start] + @data[:returned])
          next_start = start + @data[:returned]
          next_start = 1001 - count if next_start > (1001 - count)

          @next_url = "#{Rs()}?q=#{u(@query)}&count=#{count}&start=" <<
              next_start.to_s
        end
      end

    rescue SearchError => e
      @error = e.message
      @data  = {:results => []}
    end
  end
end
