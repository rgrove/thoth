class PageController < Ramaze::Controller
  engine :Erubis
  
  helper :admin
  helper :cache
  helper :error

  layout '/layout/main'
  
  if ENABLE_CACHE
    cache :index, :ttl => 60, :key => lambda { check_auth }
  end
  
  def index(name = nil)
    error_404 unless name && @page = Page[:name => name.strip.downcase]
    @title = @page.title
  end
end
