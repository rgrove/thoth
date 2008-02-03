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

class ArchiveController < Ramaze::Controller
  engine :Erubis
  helper :admin, :cache, :partial
  layout '/layout/main'

  if Riposte::Config::ENABLE_CACHE
    cache :index, :ttl => 120, :key => lambda { check_auth }
  end

  def index(page = 1)
    page = page.to_i
    page = 1 unless page >= 1
  
    @posts = Post.recent(page, 10)
  
    if page > @posts.page_count
      page = @posts.page_count
      @posts = Post.recent(page, 10)
    end

    @title      = Riposte::Config::SITE_NAME + ' Archives'
    @page_start = @posts.current_page_record_range.first
    @page_end   = @posts.current_page_record_range.last
    @total      = @posts.pagination_record_count
    @prev_url   = @posts.prev_page ? Rs(@posts.prev_page) : nil
    @next_url   = @posts.next_page ? Rs(@posts.next_page) : nil
  end
end
