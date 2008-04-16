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

class MainController < Ramaze::Controller
  helper :admin, :cache, :error, :ysearch
  layout '/layout'
  
  deny_layout :atom, :rss, :sitemap
  
  view_root Thoth::Config.theme.view,
            Thoth::VIEW_DIR
  
  if Thoth::Config.server.enable_cache
    cache :index, :ttl => 60, :key => lambda {
      check_auth.to_s + (request[:type] || '') + flash.inspect
    }
    cache :atom, :rss, :ttl => 60
    cache :sitemap, :ttl => 3600
  end

  def index
    # Check for legacy feed requests and redirect if necessary.
    if type = request[:type]
      redirect Rs(type), :status => 301      
    end
    
    @title    = Thoth::Config.site.name
    @posts    = Post.recent
    @next_url = @posts.next_page ? Rs(:archive, @posts.next_page) : nil
  end
  
  def atom
    response['Content-Type'] = 'application/atom+xml'
    
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!
    
    x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      x.id       Thoth::Config.site.url
      x.title    Thoth::Config.site.name
      x.subtitle Thoth::Config.site.desc
      x.updated  Time.now.xmlschema # TODO: use modification time of the last post
      x.link     :href => Thoth::Config.site.url
      x.link     :href => Thoth::Config.site.url.chomp('/') + Rs(:atom),
                 :rel => 'self'
      
      x.author {
        x.name  Thoth::Config.admin.name
        x.email Thoth::Config.admin.email
        x.uri   Thoth::Config.site.url
      }
      
      Post.recent.all.each do |post|
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
  
  def rss
    response['Content-Type'] = 'application/rss+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    x.rss(:version     => '2.0',
          'xmlns:atom' => 'http://www.w3.org/2005/Atom') {
      x.channel {
        x.title          Thoth::Config.site.name
        x.link           Thoth::Config.site.url
        x.description    Thoth::Config.site.desc
        x.managingEditor "#{Thoth::Config.admin.email} (#{Thoth::Config.admin.name})"
        x.webMaster      "#{Thoth::Config.admin.email} (#{Thoth::Config.admin.name})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            60
        x.atom           :link, :rel => 'self', :type => 'application/rss+xml',
                         :href => Thoth::Config.site.url.chomp('/') +
                                  Rs(:rss)
        
        Post.recent.all.each do |post|
          x.item {
            x.title       post.title
            x.link        post.url
            x.guid        post.url, :isPermaLink => 'true'
            x.pubDate     post.created_at.rfc2822
            x.description post.body_rendered
            
            post.tags.each do |tag|
              x.category tag.name, :domain => tag.url
            end
          }
        end
      }
    }
  end
  
  def sitemap
    error_404 unless Thoth::Config.site.enable_sitemap

    response['Content-Type'] = 'text/xml'
    
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!
    
    x.urlset(:xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9') {
      x.url {
        x.loc        Thoth::Config.site.url
        x.changefreq 'hourly'
        x.priority   '1.0'
      }
      
      Page.reverse_order(:updated_at).all do |page|
        x.url {
          x.loc        page.url
          x.lastmod    page.updated_at.xmlschema
          x.changefreq 'weekly'
          x.priority   '0.6'
        }
      end
      
      now = Time.now
      
      Post.reverse_order(:updated_at).all do |post|
        x.url {
          x.loc        post.url
          x.lastmod    post.updated_at.xmlschema
          x.changefreq 'weekly'
        }
      end
    }
  end
  
  # Legacy redirect to /archive/+page+.
  def archives(page = 1)
    redirect R(ArchiveController, page), :status => 301
  end
  
  # Legacy redirect to /post/+name+.
  def article(name)
    redirect R(PostController, name), :status => 301
  end
  
  # Legacy redirect to /comment.
  def comments
    if type = request[:type]
      redirect R(CommentController, type), :status => 301
    else
      redirect R(CommentController), :status => 301
    end  
  end
  
  alias_method 'recent-comments', :comments

end
