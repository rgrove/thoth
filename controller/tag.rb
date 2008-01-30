class TagController < Ramaze::Controller
  engine :Erubis

  helper :cache
  helper :error
  helper :partial

  layout '/layout/main'

  cache :index, :ttl => 60 if ENABLE_CACHE

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
  end
end
