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
  class PageApiController < Ramaze::Controller
    map '/api/page'

    helper :admin, :aspect, :error

    before_all do
      Ramaze::Session.current.drop! if Ramaze::Session.current
    end

    # Returns a response indicating whether the specified page name is valid and
    # not already taken. Returns an HTTP 200 response on success or an HTTP 500
    # response on error.
    #
    # ==== Query Parameters
    #
    # name:: page name to check
    #
    # ==== Sample Response
    #
    #   {"valid":true,"unique":true}
    #
    def check_name
      error_403 unless auth_key_valid?

      unless request[:name] && request[:name].length > 0
        error_400('Missing required parameter: name')
      end

      response['Content-Type'] = 'application/json'

      name = request[:name].to_s

      JSON.generate({
        :valid  => Page.name_valid?(name),
        :unique => Page.name_unique?(name)
      })
    end

    # Suggests a valid and unique name for the specified page title. Returns an
    # HTTP 200 response on success or an HTTP 500 response on error.
    #
    # ==== Query Parameters
    #
    # title:: page title
    #
    # ==== Sample Response
    #
    #   {"name":"ninjas-are-awesome"}
    #
    def suggest_name
      error_403 unless auth_key_valid?

      unless request[:title] && request[:title].length > 0
        error_400('Missing required parameter: title')
      end

      response['Content-Type'] = 'application/json'

      JSON.generate({"name" => Page.suggest_name(request[:title])})
    end

    # updates the display_order fields of two pages in response to a drop action.
    # essentially just swaps the display_order values for two pages
    # HTTP 200 on success, HTTP 500 on error.
    #
    # ==== Query Parameters
    # page_1:: id of first page
    # page_2:: id of second page
    # 
    # ==== Sample Response
    #
    #   {"page_1": 2, "page_2": 1} // indicates that page with id 1 now has display_order of 2, etc.    
    def update_display_order
      error_403 unless auth_key_valid?
      
      unless request[:page_1] && request[:page_1].length > 0
        error_400('Missing required parameter: page_1')
      end
      
      unless request[:page_2] && request[:page_2].length > 0
        error_400('Missing required parameter: page_2')
      end
      
      # find the relevant pages:
      page1 = Page[:id => request[:page_1]]
      page2 = Page[:id => request[:page_2]]
      
      if (page1.nil? or page2.nil?)
        error_400('Invalid page ids...')
      end
      
      temp_display_order = page1.display_order
      page1.display_order = page2.display_order
      page2.display_order = temp_display_order
      
      begin
        page1.save
        page2.save
      rescue => e
        error_400("Error saving page: #{e}")
      end
      
      JSON.generate({
        :page_1  => page1.display_order,
        :page_2 => page2.display_order
      })
      
      
    end

  end
end
