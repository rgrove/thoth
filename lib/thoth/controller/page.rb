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
  class PageController < Controller
    map '/page'
    helper :pagination, :wiki

    if Config.server.enable_cache
      cache :index, :ttl => 120, :key => lambda { auth_key_valid? }
    end

    def index(name = nil)
      error_404 unless name && @page = Page[:name => name.strip.downcase]

      @title          = @page.title
      @show_page_edit = true
    end

    def delete(id = nil)
      require_auth

      error_404 unless id && @page = Page[id]

      if request.post?
        error_403 unless form_token_valid?

        if request[:confirm] == 'yes'
          @page.destroy
          Ramaze::Cache.action.clear
          flash[:success] = 'Page deleted.'
          redirect(MainController.r())
        else
          redirect(@page.url)
        end
      end

      @title          = "Delete Page: #{@page.title}"
      @show_page_edit = true
    end

    def edit(id = nil)
      require_auth

      unless @page = Page[id]
        flash[:error] = 'Invalid page id.'
        redirect(rs(:new))
      end

      if request.post?
        error_403 unless form_token_valid?

        @page.name  = request[:name]
        @page.title = request[:title]
        @page.body  = request[:body]

        if @page.valid? && request[:action] == 'Post'
          begin
            raise unless @page.save
          rescue => e
            @page_error = "There was an error saving your page: #{e}"
          else
            Ramaze::Cache.action.clear
            flash[:success] = 'Page saved.'
            redirect(rs(@page.name))
          end
        end
      end

      @title          = "Edit page - #{@page.title}"
      @form_action    = rs(:edit, id)
      @show_page_edit = true
    end

    def list(page = 1)
      require_auth

      # If this is a POST request, set page display positions.
      if request.post? && !request[:position].nil? &&
          request[:position].is_a?(Hash)

        error_403 unless form_token_valid?

        Page.normalize_positions

        Page.order(:position).all do |p|
          unless request[:position][p.id.to_s].nil? ||
             request[:position][p.id.to_s].to_i == p.position
            Page.set_position(p, request[:position][p.id.to_s].to_i)
          end
        end

        Page.normalize_positions
      end

      page = page.to_i

      @columns  = [:name, :title, :created_at, :updated_at, :position]
      @order    = (request[:order] || :asc).to_sym
      @sort     = (request[:sort]  || :display_order).to_sym
      @sort     = :position unless @columns.include?(@sort)
      @sort_url = rs(:list, page)

      @pages = Page.paginate(page, 20).order(@order == :desc ? @sort.desc :
         @sort)

      @title        = "Pages (page #{page} of #{[@pages.page_count, 1].max})"
      @pager        = pager(@pages, rs(:list, '__page__', :sort => @sort, :order => @order))
      @form_action  = rs(:list)
    end

    def new
      require_auth

      @title       = "New page - Untitled"
      @form_action = rs(:new)

      if request.post?
        error_403 unless form_token_valid?

        @page = Page.new do |p|
          p.name     = request[:name]
          p.title    = request[:title]
          p.body     = request[:body]
          p.position = Page.dataset.max(:position).to_i + 1
        end

        if @page.valid? && request[:action] == 'Post'
          begin
            raise unless @page.save
          rescue => e
            @page_error = "There was an error saving your page: #{e}"
          else
            Ramaze::Cache.action.clear
            flash[:success] = 'Page created.'
            redirect(rs(@page.name))
          end
        end

        @title = "New page - #{@page.title}"
      end
    end
  end
end
