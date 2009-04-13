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
  class MinifyController < Controller
    map '/minify'

    helper :cache, :error

    def css(*args)
      path = 'css/' << args.join('/')
      file = process(path)

      Ramaze::Session.current.drop! if Ramaze::Session.current

      response['Content-Type'] = 'text/css'

      # If the filename has a -min suffix, assume that it's already minified and
      # serve it as is.
      if (File.basename(path, '.css') =~ /-min$/)
        response.body = File.open(file, 'rb')
        throw(:respond)
      end

      if Config.server.enable_cache
        response.body = value_cache[path] ||
            value_cache[path] = CSSMin.minify(File.open(file, 'rb'))
      else
        response.body = CSSMin.minify(File.open(file, 'rb'))
      end

      throw(:respond)
    end

    def js(*args)
      path = 'js/' << args.join('/')
      file = process(path)

      Ramaze::Session.current.drop! if Ramaze::Session.current

      response['Content-Type'] = 'text/javascript'

      # If the filename has a -min suffix, assume that it's already minified and
      # serve it as is.
      if (File.basename(path, '.js') =~ /-min$/)
        response.body = File.open(file, 'rb')
        throw(:respond)
      end

      if Config.server.enable_cache
        response.body = value_cache[path] ||
            value_cache[path] = JSMin.minify(File.open(file, 'rb'))
      else
        response.body = JSMin.minify(File.open(file, 'rb'))
      end

      throw(:respond)
    end

    private

    def process(path)
      file = Ramaze::Dispatcher::File.resolve_path(path)

      unless File.file?(file) && Ramaze::Dispatcher::File.in_public?(file)
        error_404
      end

      mtime = File.mtime(file)

      response['Last-Modified'] = mtime.httpdate
      response['ETag'] = Digest::MD5.hexdigest(file + mtime.to_s).inspect

      if modified_since = request.env['HTTP_IF_MODIFIED_SINCE']
        unless Time.parse(modified_since) < mtime
          response.build([], 304)
          throw(:respond)
        end
      elsif match = request.env['HTTP_IF_NONE_MATCH']
        if response['ETag'] == match
          response.build([], 304)
          throw(:respond)
        end
      end

      file
    end
  end
end
