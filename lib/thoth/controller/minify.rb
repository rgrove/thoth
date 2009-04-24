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
    helper :cache

    def css(*args)
      path = 'css/' << args.join('/')
      file = process(path)

      response['Content-Type'] = 'text/css'

      # If the filename has a -min suffix, assume that it's already minified and
      # serve it as is.
      if (File.basename(path, '.css') =~ /-min$/)
        throw(:respond, File.open(file, 'rb'))
      end

      if Config.server.enable_cache
        body = cache_value[path] ||= CSSMin.minify(File.open(file, 'rb'))
      else
        body = CSSMin.minify(File.open(file, 'rb'))
      end

      throw(:respond, body)
    end

    def js(*args)
      path = 'js/' << args.join('/')
      file = process(path)

      response['Content-Type'] = 'application/javascript'

      # If the filename has a -min suffix, assume that it's already minified and
      # serve it as is.
      if (File.basename(path, '.js') =~ /-min$/)
        throw(:respond, File.open(file, 'rb'))
      end

      if Config.server.enable_cache
        body = cache_value[path] ||= JSMin.minify(File.open(file, 'rb'))
      else
        body = JSMin.minify(File.open(file, 'rb'))
      end

      throw(:respond, body)
    end

    private

    def process(path)
      error_404 unless file = resolve_path(path)

      response['Cache-Control'] = 'max-age=3600'
      response['Last-Modified'] = File.mtime(file).httpdate

      file
    end

    def resolve_path(path)
      root_mappings.each do |root|
        options.publics.each do |pub|
          joined = File.join(root, pub, path)
          return joined if File.file?(joined)
        end
      end

      return false
    end

  end
end
