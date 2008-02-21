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
  engine :Erubis
  helper :admin, :cache, :cookie, :error
  layout '/layout'

  template_root Riposte::Config.theme.view/:comment,
                Riposte::VIEW_DIR/:comment
  
  if Riposte::Config.server.enable_cache
    cache :index, :ttl => 60, :key => lambda { check_auth }
    cache :atom, :rss, :ttl => 60
  end

  def index
    now = Time.now.strftime('%Y%j')
    
    comments = Comment.recent.partition do |comment|
      comment.created_at('%Y%j') == now
    end

    @title = 'Recent Comments'
    @today, @ancient = comments
  end
  
  def atom
    response.header['Content-Type'] = 'application/atom+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    respond x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      comments_url = Riposte::Config.site.url.chomp('/') + Rs()
      
      x.id       comments_url
      x.title    "#{Riposte::Config.site.name}: Recent Comments"
      x.subtitle Riposte::Config.site.desc
      x.updated  Time.now.xmlschema # TODO: use modification time of the last post
      x.link     :href => comments_url
      x.link     :href => Riposte::Config.site.url.chomp('/') + Rs(:atom),
                 :rel => 'self'

      Comment.recent.all.each do |comment|
        x.entry {
          x.id        comment.url
          x.title     comment.title, :type => 'html'
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
      comment_url = @comment.url
      
      if request[:confirm] == 'yes'
        @comment.destroy
        action_cache.clear  
      end
      
      redirect(comment_url)
    end
    
    @title = "Delete Comment: #{@comment.title}"
  end
  
  def list(page = 1)
    require_auth
    
    @comments = Comment.recent(page.to_i, 20)
    @prev_url = @comments.prev_page ? Rs(:list, @comments.prev_page) : nil
    @next_url = @comments.next_page ? Rs(:list, @comments.next_page) : nil
    @title    = "Comments (page #{page} of #{@comments.page_count})"
  end
  
  def new(name)
    redirect(R(PostController, name)) unless request.post?
    
    error_404 unless @post = Post.get(name)

    # Dump the request if the robot traps were triggered.
    error_404 unless request['captcha'].empty? && request['comment'].empty?
    
    # Create a new comment.
    comment = Comment.new do |c|
      c.post_id    = @post.id
      c.author     = request[:author]
      c.author_url = request[:author_url]
      c.title      = request[:title]
      c.body       = request[:body]
      c.ip         = request.ip
    end
    
    # Set cookies.
    expire = Time.now + 5184000 # two months from now

    response.set_cookie(:riposte_author, :expires => expire, :path => '/',
        :value => comment.author)
    response.set_cookie(:riposte_author_url, :expires => expire, :path => '/',
        :value => comment.author_url)

    if comment.valid? && request[:action] == 'Post Comment'
      begin
        raise unless comment.save
      rescue => e
        @comment_error = 'There was an error posting your comment. Please ' +
            'try again later.'
      else
        redirect(R(PostController, @post.name) + "#comment-#{comment.id}")
      end
    end

    @title      = @post.title
    @author     = comment.author
    @author_url = comment.author_url
    @preview    = comment

    render_template('../post/index')
  end
  
  def rss
    response.header['Content-Type'] = 'application/rss+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    respond x.rss(:version     => '2.0',
                  'xmlns:atom' => 'http://www.w3.org/2005/Atom',
                  'xmlns:dc'   => 'http://purl.org/dc/elements/1.1/') {
      x.channel {
        x.title          "#{Riposte::Config.site.name}: Recent Comments"
        x.link           Riposte::Config.site.url
        x.description    Riposte::Config.site.desc
        x.managingEditor "#{Riposte::Config.admin.email} (#{Riposte::Config.admin.name})"
        x.webMaster      "#{Riposte::Config.admin.email} (#{Riposte::Config.admin.name})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            30
        x.atom           :link, :rel => 'self', :type => 'application/rss+xml',
                         :href => Riposte::Config.site.url.chomp('/') +
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
