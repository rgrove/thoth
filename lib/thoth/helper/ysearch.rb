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

module Ramaze; module Helper

  # The YSearch helper provides search results using the Yahoo! Search API.
  # Requires the json or json_pure gem.
  module Ysearch
    class SearchError < Ramaze::Error; end

    # Yahoo! Developer API key. Feel free to replace this with your own key.
    API_ID = 'pNi6xQDV34FbvnO3QRfWKSByhmPFG.3fVS_R2KzOhMek3szHWKNBrTsdi1mob2vZgKjLoLuZ4A--'

    # Yahoo! Search API URL.
    API_URL = 'http://search.yahooapis.com/WebSearchService/V1/webSearch'

    private

    # Performs a web search using the Yahoo! Search API and returns the results
    # as a Hash. For details on the available options, see
    # http://developer.yahoo.com/search/web/V1/webSearch.html
    def yahoo_search(query, options = {})
      options = {:format => 'html'}.merge(options).collect{|key, val|
          "#{key.to_s}=#{::CGI.escape(val.to_s)}"}.join('&')

      request = "#{API_URL}?appid=#{API_ID}&query=#{::CGI.escape(query)}&" +
          options + '&output=json'

      r = JSON.parse(open(request).read)['ResultSet']

      # Parse the response into a more Rubyish format.
      data = {
        :available => r['totalResultsAvailable'],
        :end       => r['totalResultsReturned'] + r['firstResultPosition'] - 1,
        :results   => [],
        :start     => r['firstResultPosition'],
        :returned  => r['totalResultsReturned']
      }

      r['Result'].each do |result|
        data[:results] << {
          :cache_size => result['Cache'] ? result['Cache']['Size'].to_i : 0,
          :cache_url  => result['Cache'] ? result['Cache']['Url'] : '',
          :click_url  => result['ClickUrl'],
          :mime       => result['MimeType'],
          :modified   => Time.at(result['ModificationDate']),
          :summary    => result['Summary'],
          :title      => result['Title'],
          :url        => result['Url']
        }
      end

      return data

    rescue => e
      raise SearchError, "Unable to retrieve search results: #{e}"
    end
  end

end; end
