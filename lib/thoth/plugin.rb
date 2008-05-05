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

  # Namespace for Thoth plugins. See
  # http://code.google.com/p/thoth-blog/wiki/CreatingPlugins for more info on
  # creating and using plugins.
  module Plugin
    def self.const_missing(name)
      self.load(name)
      self.const_get(name)
    end

    # Attempts to load the specified plugin, first from Thoth's
    # <tt>/plugin</tt> directory, then as a gem.
    def self.load(name)
      plugin = "thoth_#{name.to_s.downcase.gsub(/^thoth_/, '')}"
      files  = Dir["{#{HOME_DIR/:plugin},#{$:.join(',')}}/#{plugin}.rb"]

      # First try to load a local copy of the plugin, then try the gem.
      unless (files.any? && require(files.first)) || require(plugin)
        raise LoadError, "Thoth::Plugin::#{name} not found"
      end

      Ramaze::Log.info "Loaded plugin: #{plugin}"

      true
    end
  end

end
