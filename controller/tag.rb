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
  engine :Erubis
  helper :admin, :cache, :error
  layout '/layout'

  template_root Riposte::Config.theme.view/:tag,
                Riposte::DIR/:view/:tag
  
  if Riposte::Config.server.enable_cache
    cache :index, :ttl => 60, :key => lambda { check_auth }
  end

  def index(name, page = 1)
    error_404 unless @tag = Tag[:name => name.strip.downcase]

    page = page.to_i
    page = 1 unless page >= 1

    @posts = @tag.posts.paginate(page, 10)

    if page > @posts.page_count
      page   = @posts.page_count
      @posts = @tag.posts.paginate(page, 10)
    end

    @title      = "Posts with the tag '#{@tag.name}'"
    @page_start = @posts.current_page_record_range.first
    @page_end   = @posts.current_page_record_range.last
    @prev_url   = @posts.prev_page ? Rs(@tag.name, @posts.prev_page) : nil
    @next_url   = @posts.next_page ? Rs(@tag.name, @posts.next_page) : nil
    @total      = @posts.pagination_record_count
  end
end
