class ArchiveController < Ramaze::Controller
  engine :Erubis

  helper :cache
  helper :partial

  layout '/layout/main'

  cache :index, :ttl => 120 if ENABLE_CACHE

  def index(page = 1)
    page = page.to_i
    page = 1 unless page >= 1
  
    @title = SITE_NAME + ' Archives'
    @posts = Post.recent(page, 10)
  
    if page > @posts.page_count
      page = @posts.page_count
      @posts = Post.recent(page, 10)
    end

    @page_start = @posts.current_page_record_range.first
    @page_end   = @posts.current_page_record_range.last
    @prev_url   = @posts.prev_page ? Rs(@posts.prev_page) : nil
    @next_url   = @posts.next_page ? Rs(@posts.next_page) : nil
  end
end
