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
  class PostApiController < Controller
    map '/api/post'

    helper :admin, :aspect

    before_all do
      Ramaze::Session.current.drop! if Ramaze::Session.current
    end

    # Returns a response indicating whether the specified post name is valid and
    # not already taken. Returns an HTTP 200 response on success or an HTTP 500
    # response on error.
    #
    # ==== Query Parameters
    #
    # name:: post name to check
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
        :valid  => Post.name_valid?(name),
        :unique => Post.name_unique?(name)
      })
    end

    # Deletes the specified comment. Returns an HTTP 200 response on success, an
    # HTTP 500 response on error, or an HTTP 404 response if the specified
    # comment does not exist.
    #
    # ==== Query Parameters (POST only)
    #
    # id::    comment id
    # token:: form token
    #
    # ==== Sample Response
    #
    # ===== Success
    #
    #   {"success":true}
    #
    # ===== Failure
    #
    #   {"error":"The comment could not be deleted due to an unknown database error."}
    #
    def delete
      error_403 unless auth_key_valid? && form_token_valid?
      error_405 unless request.post?
      error_404 unless request[:id] && @comment = Comment[request[:id]]

      response['Content-Type'] = 'application/json'

      if @comment.destroy
        action_cache.clear
        JSON.generate({:success => true})
      else
        respond(JSON.generate({
          :error => 'The comment could not be deleted due to an unknown ' <<
              'database error.'
        }, 500))
      end
    end

    # Suggests a valid and unique name for the specified post title. Returns an
    # HTTP 200 response on success or an HTTP 500 response on error.
    #
    # ==== Query Parameters
    #
    # title:: post title
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

      JSON.generate({"name" => Post.suggest_name(request[:title])})
    end
  end
end
