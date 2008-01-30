require 'cgi'
require 'json'
require 'open-uri'

module Ramaze
  
  # Helper that provides search results using the Yahoo! Search API. Requires
  # the json or json_pure gem.
  module YsearchHelper
    class SearchError < Ramaze::Error; end
    
    API_ID  = 'pNi6xQDV34FbvnO3QRfWKSByhmPFG.3fVS_R2KzOhMek3szHWKNBrTsdi1mob2vZgKjLoLuZ4A--'
    API_URL = 'http://search.yahooapis.com/WebSearchService/V1/webSearch'
    
    private

    # Performs a web search using the Yahoo! Search API and returns the results
    # as a Hash. For details on the available options, see
    # http://developer.yahoo.com/search/web/V1/webSearch.html
    def yahoo_search(query, options = {})
      options = {:format => 'html'}.merge(options).collect{|key, val|
          "#{key.to_s}=#{CGI.escape(val.to_s)}"}.join('&')
      
      request = "#{API_URL}?appid=#{API_ID}&query=#{CGI.escape(query)}&" +
          options + '&output=json'
      
      r = JSON.parse(open(request).read)['ResultSet']
      
      # Parse the response into a less annoying format.
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
      raise SearchError, 'Unable to retrieve search results.'
    end
    
  end
end
