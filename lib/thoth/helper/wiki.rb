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

module Thoth; module Helper

  module Wiki
    private

    # Parse wiki-style markup into HTML markup.
    def wiki_to_html(string)
      # [[page_name|link text]]
      string.gsub!(/\[\[([0-9a-z_-]+)\|(.+?)\]\]/i) do
        PageController.a($2, :/, $1.downcase)
      end

      # [[page_name]]
      string.gsub!(/\[\[([0-9a-z_-]+)\]\]/i) do
        PageController.a($1, :/, $1.downcase)
      end

      # [[@post_name|link text]]
      # [[@123|link text]]
      string.gsub!(/\[\[@(\d+|[0-9a-z_-]+)\|(.+?)\]\]/i) do
        PostController.a($2, :/, $1.downcase)
      end

      # [[@post_name]]
      # [[@123]]
      string.gsub!(/\[\[@(\d+|[0-9a-z_-]+)\]\]/i) do
        PostController.a($1, :/, $1.downcase)
      end

      # [[media:filename|link text]]
      string.gsub!(/\[\[media:([^\]]+)\|(.+?)\]\]/i) do
        MediaController.a($2, :/, $1)
      end

      # [[media:filename]]
      string.gsub!(/\[\[media:([^\]]+)\]\]/i) do
        MediaController.a($1, :/, $1)
      end

      # [[media_url:filename]]
      string.gsub!(/\[\[media_url:([^\]]+)\]\]/i) do
        MediaController.r(:/, $1).to_s
      end

      string
    end
  end

end; end
