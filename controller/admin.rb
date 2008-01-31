class AdminController < Ramaze::Controller
  engine :Erubis

  helper :admin
  helper :error
  helper :partial

  layout '/layout/main'
  
  def index
    # TODO: Some kind of dashboard display or something?
  end
  
  def page_edit(id)
    if @page = Page[id]
      @title       = "Edit page - #{@page.title}"
      @form_action = Rs(:page_edit, id)
      
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
            redirect(R(PageController, @page.name))
          end
        end
      end
    else
      @title       = 'New page - Untitled'
      @page_error  = 'Invalid page id.'
      @form_action = Rs(:page_new)
    end
  end
  
  def page_new
    @title       = "New page - Untitled"
    @form_action = Rs(:page_new)
    
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
          redirect(R(PageController, @page.name))
        end
      end
      
      @title = "New page - #{@page.title}"
    end
  end
  
  def post_edit(id)
    if @post = Post[id]
      @title       = "Edit blog post - #{@post.title}"
      @form_action = Rs(:post_edit, id)
      
      if request.post?
        @post.title = request[:title]
        @post.body  = request[:body]
        @post.tags  = request[:tags]
        
        if @post.valid? && request[:action] === 'Post'
          begin
            DB.transaction do
              raise unless @post.save && @post.tags = request[:tags]
            end
          rescue => e
            @post_error = "There was an error saving your post: #{e}"
          else
            redirect(R(PostController, @post.name))
          end
        end
      end
    else
      @title       = 'New blog post - Untitled'
      @post_error  = 'Invalid post id.'
      @form_action = Rs(:post_new)
    end
  end
  
  def post_new
    @title       = "New blog post - Untitled"
    @form_action = Rs(:post_new)
    
    if request.post?
      @post = Post.new(
        :title => request[:title],
        :body  => request[:body],
        :tags  => request[:tags]
      )
      
      if @post.valid? && request[:action] === 'Post'
        begin
          DB.transaction do
            raise unless @post.save && @post.tags = request[:tags]
          end
        rescue => e
          @post_error = "There was an error saving your post: #{e}"
        else
          redirect(R(PostController, @post.name))
        end
      end
      
      @title = "New blog post - #{@post.title}"
    end
  end
  
end
