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

require 'cssmin'
require 'jsmin'

module Thoth

  # Rack middleware that intercepts and minifies CSS and JavaScript responses,
  # caching the minified content to speed up future requests.
  class Minify

    MINIFIERS = {
      'application/javascript' => JSMin,
      'text/css'               => CSSMin,
      'text/javascript'        => JSMin
    }

    EXCLUDE = [
      /-min\.(?:css|js)$/i
    ]

    def initialize(app)
      @app = app

      if Config.server['enable_cache']
        Ramaze::Cache.add(:minify) unless Ramaze::Cache.respond_to?(:minify)
        @cache = Ramaze::Cache.minify
      end
    end

    def call(env)
      @status, @headers, @body = @app.call(env)

      unless @status == 200 && @minifier = MINIFIERS[@headers['Content-Type']]
        return [@status, @headers, @body]
      end

      @path = Rack::Utils.unescape(env['PATH_INFO'])

      EXCLUDE.each {|ex| return [@status, @headers, @body] if @path =~ ex }

      @headers.delete('Content-Length')
      @headers['Cache-Control'] = 'max-age=3600,public'

      [@status, @headers, self]
    end

    def each
      content = ''
      @body.each {|part| content << part.to_s }

      if Config.server['enable_cache']
        @body = @cache["minify_#{@path}"] ||= @minifier.minify(content)
      else
        @body = @minifier.minify(content)
      end

      yield @body
    end

  end
end
