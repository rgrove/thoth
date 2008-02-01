class PageController < Ramaze::Controller
  engine :Erubis
  
  helper :admin
  helper :cache
  helper :error
  helper :partial

  layout '/layout/main'
  
  if ENABLE_CACHE
    cache :index, :ttl => 60, :key => lambda { check_auth }
  end
  
  def index(name = nil)
    error_404 unless name && @page = Page[:name => name.strip.downcase]
    @title = @page.title
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
        
        if @page.valid? && request[:action] === 'Post'
          begin
            raise unless @page.save
          rescue => e
            @page_error = "There was an error saving your page: #{e}"
          else
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

  def new
    require_auth
    
    @title       = "New page - Untitled"
    @form_action = Rs(:new)
    
    if request.post?
      @page = Page.new(
        :name  => request[:name],
        :title => request[:title],
        :body  => request[:body]
      )
      
      if @page.valid? && request[:action] === 'Post'
        begin
          raise unless @page.save
        rescue => e
          @page_error = "There was an error saving your page: #{e}"
        else
          redirect(Rs(@page.name))
        end
      end
      
      @title = "New page - #{@page.title}"
    end
  end
end
