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

class PageController < Ramaze::Controller
  engine :Erubis  
  helper :admin, :cache, :error, :wiki
  layout '/layout'
  
  template_root Riposte::Config.theme.view/:page,
                Riposte::VIEW_DIR/:page
  
  if Riposte::Config.server.enable_cache
    cache :index, :ttl => 60, :key => lambda { check_auth }
  end
  
  def index(name = nil)
    error_404 unless name && @page = Page[:name => name.strip.downcase]
    @title = @page.title
  end
  
  def delete(id = nil)
    require_auth
    
    error_404 unless id && @page = Page[id]

    if request.post?
      if request[:confirm] == 'yes'
        @page.destroy
        action_cache.clear
        redirect(R(MainController))
      else
        redirect(@page.url)
      end
    end
    
    @title = "Delete Page: #{@page.title}"
  end
  
  def edit(id = nil)
    require_auth

    if @page = Page[id]
      @title       = "Edit page - #{@page.title}"
      @form_action = Rs(:edit, id)
      
      if request.post?
        @page.name  = request[:name]
        @page.title = request[:title]
        @page.body  = request[:body]
        
        if @page.valid? && request[:action] == 'Post'
          begin
            raise unless @page.save
          rescue => e
            @page_error = "There was an error saving your page: #{e}"
          else
            action_cache.clear
            redirect(Rs(@page.name))
          end
        end
      end
    else
      @title       = 'New page - Untitled'
      @page_error  = 'Invalid page id.'
      @form_action = Rs(:new)
    end
  end

  def list(page = 1)
    require_auth
    
    @pages    = Page.reverse_order(:created_at).paginate(page.to_i, 20)
    @prev_url = @pages.prev_page ? Rs(:list, @pages.prev_page) : nil
    @next_url = @pages.next_page ? Rs(:list, @pages.next_page) : nil
    @title    = "Pages (page #{page} of #{@pages.page_count})"
  end
  
  def new
    require_auth
    
    @title       = "New page - Untitled"
    @form_action = Rs(:new)
    
    if request.post?
      @page = Page.new do |p|
        p.name  = request[:name]
        p.title = request[:title]
        p.body  = request[:body]
      end
      
      if @page.valid? && request[:action] == 'Post'
        begin
          raise unless @page.save
        rescue => e
          @page_error = "There was an error saving your page: #{e}"
        else
          action_cache.clear
          redirect(Rs(@page.name))
        end
      end
      
      @title = "New page - #{@page.title}"
    end
  end
end
