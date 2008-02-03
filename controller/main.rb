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
  engine :Erubis
  helper :admin, :cache, :error, :partial, :redirect, :ysearch
  layout '/layout/main'
  
  if Riposte::Config::ENABLE_CACHE
    cache :index, :ttl => 60, :key => lambda { check_auth }
    cache :atom, :rss, :ttl => 60
  end

  def index
    # Check for legacy feed requests and redirect if necessary.
    if type = request[:type]
      redirect Rsa(type), :status => 301      
    end
    
    @title    = Riposte::Config::SITE_NAME
    @posts    = Post.recent
    @next_url = @posts.next_page ? Rsa(:archive, @posts.next_page) : nil
  end
  
  def atom
    response.header['Content-Type'] = 'application/atom+xml'
    
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!
    
    respond x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      x.id       Riposte::Config::SITE_URL
      x.title    Riposte::Config::SITE_NAME
      x.subtitle Riposte::Config::SITE_DESCRIPTION
      x.updated  Time.now.rfc2822 # TODO: use modification time of the last post
      x.link     :href => Riposte::Config::SITE_URL
      x.link     :href => Riposte::Config::SITE_URL.chomp('/') + Rsa(:atom),
                 :rel => 'self'
      
      x.author {
        x.name  Riposte::Config::AUTHOR_NAME
        x.email Riposte::Config::AUTHOR_EMAIL
        x.uri   Riposte::Config::SITE_URL
      }
      
      Post.recent.all.each do |post|
        x.entry {
          x.id        post.url
          x.title     post.title, :type => 'html'
          x.published post.created_at.xmlschema
          x.updated   post.updated_at.xmlschema
          x.link      post.url, :rel => 'alternate'
          x.content   post.body_rendered, :type => 'html'
          
          post.tags.each do |tag|
            x.category :term => tag.name, :label => tag.name, :scheme => tag.url
          end
        }
      end
    }
  end
  
  def rss
    response.header['Content-Type'] = 'application/rss+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    respond x.rss(:version => '2.0') {
      x.channel {
        x.title          Riposte::Config::SITE_NAME
        x.link           Riposte::Config::SITE_URL
        x.description    Riposte::Config::SITE_DESCRIPTION
        x.managingEditor "#{Riposte::Config::AUTHOR_EMAIL} (#{Riposte::Config::AUTHOR_NAME})"
        x.webMaster      "#{Riposte::Config::AUTHOR_EMAIL} (#{Riposte::Config::AUTHOR_NAME})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            60
        
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
  
  # Legacy redirect to /archive/+page+.
  def archives(page = 1)
    redirect Ra(ArchiveController, page), :status => 301
  end
  
  # Legacy redirect to /post/+name+.
  def article(name)
    redirect Ra(PostController, name), :status => 301
  end
  
  # Legacy redirect to /comments.
  def recent_comments
    if type = request[:type]
      redirect Ra(CommentsController, type), :status => 301
    else
      redirect Ra(CommentsController), :status => 301
    end  
  end
  
  alias_method 'recent-comments', :recent_comments
  
end
