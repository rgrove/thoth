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

class CommentController < Ramaze::Controller
  helper :admin, :aspect, :cache, :cookie, :pagination, :error
  layout '/layout'

  deny_layout :atom, :rss

  view_root Thoth::Config.theme.view/:comment,
            Thoth::VIEW_DIR/:comment

  if Thoth::Config.server.enable_cache
    cache :index, :ttl => 60, :key => lambda { auth_key_valid? }
    cache :atom, :rss, :ttl => 60
  end

  before_all { error_404 unless Thoth::Config.site.enable_comments }

  def index
    now = Time.now.strftime('%Y%j')

    comments = Comment.recent.partition do |comment|
      comment.created_at('%Y%j') == now
    end

    @title = 'Recent Comments'
    @today, @ancient = comments
  end

  def atom
    response['Content-Type'] = 'application/atom+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      comments_url = Thoth::Config.site.url.chomp('/') + Rs()

      x.id       comments_url
      x.title    "#{Thoth::Config.site.name}: Recent Comments"
      x.subtitle Thoth::Config.site.desc
      x.updated  Time.now.xmlschema # TODO: use modification time of the last post
      x.link     :href => comments_url
      x.link     :href => Thoth::Config.site.url.chomp('/') + Rs(:atom),
                 :rel => 'self'

      Comment.recent.all.each do |comment|
        x.entry {
          x.id        comment.url
          x.title     comment.title
          x.published comment.created_at.xmlschema
          x.updated   comment.updated_at.xmlschema
          x.link      :href => comment.url, :rel => 'alternate'
          x.content   comment.body_rendered, :type => 'html'

          x.author {
            x.name comment.author

            if comment.author_url && !comment.author_url.empty?
              x.uri comment.author_url
            end
          }
        }
      end
    }
  end

  def delete(id = nil)
    require_auth

    error_404 unless id && @comment = Comment[id]

    if request.post?
      error_403 unless form_token_valid?

      comment_url = @comment.url

      if request[:confirm] == 'yes'
        @comment.destroy
        action_cache.clear

        flash[:success] = 'Comment deleted.'
      end

      redirect(comment_url)
    end

    @title = "Delete Comment: #{@comment.title}"
  end

  def list(page = 1)
    require_auth

    page = page.to_i

    @columns  = [:id, :title, :author, :created_at]
    @order    = (request[:order] || :desc).to_sym
    @sort     = (request[:sort]  || :created_at).to_sym
    @sort     = :created_at unless @columns.include?(@sort)
    @sort_url = Rs(:list, page)

    @comments = Comment.paginate(page, 20).order(@order == :desc ?
        @sort.desc : @sort)
    @title = "Comments (page #{page} of #{@comments.page_count})"
    @pager = pager(@comments, Rs(:list, '%s', :sort => @sort, :order => @order))
  end

  def rss
    response['Content-Type'] = 'application/rss+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    x.rss(:version     => '2.0',
          'xmlns:atom' => 'http://www.w3.org/2005/Atom',
          'xmlns:dc'   => 'http://purl.org/dc/elements/1.1/') {
      x.channel {
        x.title          "#{Thoth::Config.site.name}: Recent Comments"
        x.link           Thoth::Config.site.url
        x.description    Thoth::Config.site.desc
        x.managingEditor "#{Thoth::Config.admin.email} (#{Thoth::Config.admin.name})"
        x.webMaster      "#{Thoth::Config.admin.email} (#{Thoth::Config.admin.name})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            30
        x.atom           :link, :rel => 'self', :type => 'application/rss+xml',
                         :href => Thoth::Config.site.url.chomp('/') +
                                  Rs(:rss)

        Comment.recent.all.each do |comment|
          x.item {
            x.title       comment.title
            x.link        comment.url
            x.dc          :creator, comment.author
            x.guid        comment.url, :isPermaLink => 'true'
            x.pubDate     comment.created_at.rfc2822
            x.description comment.body_rendered
          }
        end
      }
    }
  end

end
