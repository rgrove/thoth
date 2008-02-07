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

class PostController < Ramaze::Controller
  engine :Erubis  
  helper :admin, :cache, :cookie, :error, :partial
  layout '/layout'
  
  template_root Riposte::Config::CUSTOM_VIEW/:post,
                Riposte::DIR/:view/:post
  
  def index(name = nil)
    error_404 unless name && @post = Post.get(name)

    @title      = @post.title
    @author     = cookie(:riposte_author, '')
    @author_url = cookie(:riposte_author_url, '')
  end
  
  def delete(id = nil)
    require_auth
    
    error_404 unless id && @post = Post[id]

    if request.post?
      if request[:confirm] == 'yes'
        @post.destroy
        action_cache.clear
        redirect(R(MainController))
      else
        redirect(@post.url)
      end
    end
    
    @title = "Delete Post: #{@post.title}"
  end
  
  def edit(id = nil)
    require_auth

    if @post = Post[id]
      @title       = "Edit blog post - #{@post.title}"
      @form_action = Rs(:edit, id)
      
      if request.post?
        @post.title = request[:title]
        @post.body  = request[:body]
        @post.tags  = request[:tags]
        
        if @post.valid? && request[:action] === 'Post'
          begin
            Riposte.db.transaction do
              raise unless @post.save && @post.tags = request[:tags]
            end
          rescue => e
            @post_error = "There was an error saving your post: #{e}"
          else
            action_cache.clear
            redirect(Rs(@post.name))
          end
        end
      end
    else
      @title       = 'New blog post - Untitled'
      @post_error  = 'Invalid post id.'
      @form_action = Rs(:new)
    end
  end
  
  def list(page = 1)
    require_auth
    
    @posts    = Post.recent(page.to_i, 20)
    @prev_url = @posts.prev_page ? Rs(:list, @posts.prev_page) : nil
    @next_url = @posts.next_page ? Rs(:list, @posts.next_page) : nil
    @title    = "Blog Posts (page #{page} of #{@posts.page_count})"
  end
  
  def new
    require_auth

    @title       = "New blog post - Untitled"
    @form_action = Rs(:new)
    
    if request.post?
      @post = Post.new(
        :title => request[:title],
        :body  => request[:body],
        :tags  => request[:tags]
      )
      
      if @post.valid? && request[:action] === 'Post'
        begin
          Riposte.db.transaction do
            raise unless @post.save && @post.tags = request[:tags]
          end
        rescue => e
          @post_error = "There was an error saving your post: #{e}"
        else
          action_cache.clear
          redirect(Rs(@post.name))
        end
      end
      
      @title = "New blog post - #{@post.title}"
    end
  end
end
