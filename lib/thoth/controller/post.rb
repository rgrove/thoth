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

module Thoth
  class PostController < Controller
    map '/post'
    helper :cache, :pagination, :wiki

    cache_action(:method => :atom, :ttl => 120)

    def index(name = nil)
      error_404 unless name && @post = Post.get(name)

      # Permanently redirect id-based URLs to name-based URLs to reduce search
      # result dupes and improve pagerank.
      raw_redirect(@post.url, :status => 301) if name =~ /^\d+$/

      cache_key = "comments_#{@post.id}"

      if request.post? && Config.site['enable_comments']
        # Dump the request if the robot traps were triggered.
        error_404 unless request['captcha'].empty? && request['comment'].empty?

        # Create a new comment.
        comment = Comment.new do |c|
          c.post_id      = @post.id
          c.author       = request[:author]
          c.author_email = request[:author_email]
          c.author_url   = request[:author_url]
          c.title        = request[:title]
          c.body         = request[:body]
          c.ip           = request.ip
        end

        # Set cookies.
        expire = Time.now + 5184000 # two months from now

        response.set_cookie(:thoth_author, :expires => expire, :path => '/',
            :value => comment.author)
        response.set_cookie(:thoth_author_email, :expires => expire,
            :path => '/', :value => comment.author_email)
        response.set_cookie(:thoth_author_url, :expires => expire, :path => '/',
            :value => comment.author_url)

        if comment.valid? && request[:action] == 'Post Comment'
          begin
            raise unless comment.save
          rescue => e
            @comment_error = 'There was an error posting your comment. ' <<
                'Please try again later.'
          else
            flash[:success] = 'Comment posted.'
            cache_value.delete(cache_key)
            redirect(rs(@post.name).to_s + "#comment-#{comment.id}")
          end
        end

        @author       = comment.author
        @author_email = comment.author_email
        @author_url   = comment.author_url
        @preview      = comment
      elsif Config.site['enable_comments']
        @author       = cookie(:thoth_author, '')
        @author_email = cookie(:thoth_author_email, '')
        @author_url   = cookie(:thoth_author_url, '')
      end

      @title = @post.title

      if Config.site['enable_comments']
        @comment_action = r(:/, @post.name).to_s + '#post-comment'

        @comments = cache_value[cache_key] ||=
            cache_value.store(cache_key, @post.comments.all, :ttl => 300)

        @feeds = [{
          :href  => @post.atom_url,
          :title => 'Comments on this post',
          :type  => 'application/atom+xml'
        }]
      end

      @show_post_edit = true
    end

    def atom(name = nil)
      error_404 unless name && post = Post.get(name)

      # Permanently redirect id-based URLs to name-based URLs to reduce search
      # result dupes and improve pagerank.
      raw_redirect(post.atom_url, :status => 301) if name =~ /^\d+$/

      response['Content-Type'] = 'application/atom+xml'

      comments = post.comments.reverse_order.limit(20)
      updated  = comments.count > 0 ? comments.first.created_at.xmlschema :
          post.created_at.xmlschema

      x = Builder::XmlMarkup.new(:indent => 2)
      x.instruct!

      x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
        x.id       post.url
        x.title    "Comments on \"#{post.title}\" - #{Config.site['name']}"
        x.updated  updated
        x.link     :href => post.url
        x.link     :href => post.atom_url, :rel => 'self'

        comments.all do |comment|
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

      throw(:respond, x.target!)
    end

    def delete(id = nil)
      require_auth

      error_404 unless id && @post = Post[id]

      if request.post?
        error_403 unless form_token_valid?

        if request[:confirm] == 'yes'
          @post.destroy
          Ramaze::Cache.action.clear
          flash[:success] = 'Blog post deleted.'
          redirect(MainController.r())
        else
          redirect(@post.url)
        end
      end

      @title          = "Delete Post: #{@post.title}"
      @show_post_edit = true
    end

    def edit(id = nil)
      require_auth

      unless @post = Post[id]
        flash[:error] = 'Invalid post id.'
        redirect(rs(:new))
      end

      if request.post?
        error_403 unless form_token_valid?

        if request[:name] && !request[:name].empty?
          @post.name = request[:name]
        end

        @post.title = request[:title]
        @post.body  = request[:body]
        @post.tags  = request[:tags]

        @post.is_draft = @post.is_draft ? request[:action] != 'Publish' :
            request[:action] == 'Unpublish & Save as Draft'

        @post.created_at = Time.now if @post.is_draft

        if @post.valid? && (@post.is_draft || request[:action] == 'Publish')
          begin
            Thoth.db.transaction do
              raise unless @post.save && @post.tags = request[:tags]
            end
          rescue => e
            @post_error = "There was an error saving your post: #{e}"
          else
            if @post.is_draft
              flash[:success] = 'Draft saved.'
              redirect(rs(:edit, @post.id))
            else
              Ramaze::Cache.action.clear
              flash[:success] = 'Blog post published.'
              redirect(rs(@post.name))
            end
          end
        end
      end

      @title          = "Edit blog post - #{@post.title}"
      @form_action    = rs(:edit, id)
      @show_post_edit = true
    end

    def list(page = 1)
      require_auth

      page = page.to_i

      @columns  = [:id, :title, :created_at, :updated_at]
      @order    = (request[:order] || :desc).to_sym
      @sort     = (request[:sort]  || :created_at).to_sym
      @sort     = :created_at unless @columns.include?(@sort)
      @sort_url = rs(:list, page)

      @posts = Post.filter(:is_draft => false).paginate(page, 20).order(
          @order == :desc ? @sort.desc : @sort)

      if page == 1
        @drafts = Post.filter(:is_draft => true).order(
            @order == :desc ? @sort.desc : @sort)
      end

      @title = "Blog Posts (page #{page} of #{[@posts.page_count, 1].max})"
      @pager = pager(@posts, rs(:list, '__page__', :sort => @sort, :order => @order))
    end

    def new
      require_auth

      @title       = "New blog post - Untitled"
      @form_action = rs(:new)

      if request.post?
        error_403 unless form_token_valid?

        @post = Post.new do |p|
          if request[:name] && !request[:name].empty?
            p.name = request[:name]
          end

          p.title    = request[:title]
          p.body     = request[:body]
          p.tags     = request[:tags]
          p.is_draft = request[:action] == 'Save & Preview'
        end

        if @post.valid?
          begin
            Thoth.db.transaction do
              raise unless @post.save && @post.tags = request[:tags]
            end
          rescue => e
            @post.is_draft = true
            @post_error    = "There was an error saving your post: #{e}"
          else
            if @post.is_draft
              flash[:success] = 'Draft saved.'
              redirect(rs(:edit, @post.id))
            else
              Ramaze::Cache.action.clear
              flash[:success] = 'Blog post published.'
              redirect(rs(@post.name))
            end
          end
        else
          @post.is_draft = true
        end

        @title = "New blog post - #{@post.title}"
      end
    end
  end
end
