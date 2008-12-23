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

module Thoth
  module Config

    class << self
      [:devel, :production].each do |env|
        Configuration.for("thoth_#{env.to_s}") {
          db "sqlite:///#{HOME_DIR}/db/#{env.to_s}.db"

          site {
            name "New Thoth Blog"
            desc "Thoth is awesome."
            url  "http://localhost:7000/"
            enable_comments true
            enable_sitemap  true
          }

          admin {
            name  "John Doe"
            email ""
            user  "thoth"
            pass  "thoth"
            seed  "43c55@051a19a/4f88a3ff+355cd1418"
          }

          theme {
            public HOME_DIR/:public
            view   HOME_DIR/:view
            css    []
            js     []
          }

          media HOME_DIR/:media

          plugins []

          server {
            adapter       :thin
            address       "0.0.0.0"
            port          7000
            compile_views env == :production
            enable_cache  env == :production
            enable_minify env == :production
            error_log     HOME_DIR/:log/"error.log"
          }

          timestamp {
            long  "%A %B %d, %Y @ %I:%M %p (%Z)"
            short "%Y-%m-%d %I:%M"
          }
        }
      end

      def load(file)
        begin
          Kernel.load(file)
        rescue LoadError => e
          raise Thoth::Error, "Unable to load config file: #{file}: #{e}"
        end

        @conf = Configuration.for("thoth_#{Thoth.trait[:mode].to_s}")
      end

      def method_missing(name)
        @conf.__send__(name)
      end
    end

  end
end
