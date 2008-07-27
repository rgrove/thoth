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

class TagController < Ramaze::Controller
  helper :admin, :cache, :error, :pagination
  layout '/layout'

  deny_layout :atom

  view_root Thoth::Config.theme.view/:tag,
            Thoth::VIEW_DIR/:tag

  if Thoth::Config.server.enable_cache
    cache :index, :ttl => 120, :key => lambda { auth_key_valid? }
    cache :atom, :ttl => 120
  end

  def index(name = nil, page = 1)
    error_404 unless name && @tag = Tag[:name => name.strip.downcase]

    page = page.to_i
    page = 1 unless page >= 1

    @posts = @tag.posts.paginate(page, 10)

    if page > @posts.page_count && @posts.page_count > 0
      page   = @posts.page_count
      @posts = @tag.posts.paginate(page, 10)
    end

    @title = "Posts tagged with \"#{@tag.name}\""
    @pager = pager(@posts, Rs(name, '%s'))

    @feeds = [{
      :href  => @tag.atom_url,
      :title => 'Posts with this tag',
      :type  => 'application/atom+xml'
    }]
  end

  def atom(name = nil)
    error_404 unless name && tag = Tag[:name => name.strip.downcase]

    posts   = tag.posts.limit(10)
    updated = posts.count > 0 ? posts.first.created_at.xmlschema :
        Time.at(0).xmlschema

    response['Content-Type'] = 'application/atom+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      x.id       tag.url
      x.title    "Posts tagged with \"#{tag.name}\" - #{Thoth::Config.site.name}"
      x.updated  updated
      x.link     :href => tag.url
      x.link     :href => tag.atom_url, :rel => 'self'

      x.author {
        x.name  Thoth::Config.admin.name
        x.email Thoth::Config.admin.email
        x.uri   Thoth::Config.site.url
      }

      posts.all do |post|
        x.entry {
          x.id        post.url
          x.title     post.title
          x.published post.created_at.xmlschema
          x.updated   post.updated_at.xmlschema
          x.link      :href => post.url, :rel => 'alternate'
          x.content   post.body_rendered, :type => 'html'

          post.tags.each do |tag|
            x.category :term => tag.name, :label => tag.name, :scheme => tag.url
          end
        }
      end
    }
  end
end
