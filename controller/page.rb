class PageController < Ramaze::Controller
  engine :Erubis
  
  helper :cache
  helper :error

  layout '/layout/main'
  
  cache :index, :ttl => 60 if ENABLE_CACHE
  
  def index(name = nil)
    error_404 unless name && @page = Page[:name => name.strip.downcase]
    @title = @page.title
  end
end
