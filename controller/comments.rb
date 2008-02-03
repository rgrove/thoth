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

class CommentsController < Ramaze::Controller
  engine :Erubis
  helper :admin, :cache
  layout '/layout/main'

  if Riposte::Config::ENABLE_CACHE
    cache :index, :ttl => 30, :key => lambda { check_auth }
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
      comments_url = Riposte::Config::SITE_URL.chomp('/') + Rs()
      
      x.id       comments_url
      x.title    "#{Riposte::Config::SITE_NAME}: Recent Comments"
      x.subtitle Riposte::Config::SITE_DESCRIPTION
      x.updated  Time.now.rfc2822 # TODO: use modification time of the last post
      x.link     :href => comments_url
      x.link     :href => Riposte::Config::SITE_URL.chomp('/') + Rs(:atom),
                 :rel => 'self'

      x.author {
        x.name  Riposte::Config::AUTHOR_NAME
        x.email Riposte::Config::AUTHOR_EMAIL
        x.uri   Riposte::Config::SITE_URL
      }

      Comment.recent.all.each do |comment|
        x.entry {
          x.id        comment.url
          x.title     comment.title, :type => 'html'
          x.published comment.created_at.xmlschema
          x.updated   comment.updated_at.xmlschema
          x.link      comment.url, :rel => 'alternate'
          x.content   comment.body_rendered, :type => 'html'
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
        x.title          "#{Riposte::Config::SITE_NAME}: Recent Comments"
        x.link           Riposte::Config::SITE_URL
        x.description    Riposte::Config::SITE_DESCRIPTION
        x.managingEditor "#{Riposte::Config::AUTHOR_EMAIL} (#{Riposte::Config::AUTHOR_NAME})"
        x.webMaster      "#{Riposte::Config::AUTHOR_EMAIL} (#{Riposte::Config::AUTHOR_NAME})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            30
        
        Comment.recent.all.each do |comment|
          x.item {
            x.title       comment.title
            x.link        comment.url
            x.author      comment.author
            x.guid        comment.url, :isPermaLink => 'true'
            x.pubDate     comment.created_at.rfc2822
            x.description comment.body_rendered
          }
        end
      }
    }
  end
  
end
