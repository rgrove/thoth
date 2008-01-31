class AdminController < Ramaze::Controller
  engine :Erubis

  helper :admin
  helper :error
  helper :flash
  helper :partial

  layout '/layout/main'
  
  def index
    # TODO: Some kind of dashboard display or something?
  end
  
  def page_edit(id)
  end
  
  def page_new
  end
  
  def post_edit(id)
  end
  
  def post_new
    @title = "New blog post - Untitled"
    
    if request.post?
      @post = Post.new(
        :name  => request[:name],
        :title => request[:title],
        :body  => request[:body],
        :tags  => request[:tags]
      )
      
      if request[:action] === 'Post'
        # TODO: Wrap this in a transaction for extra safety
        if @post.save && @post.tags = request[:tags]
          redirect(R(PostController, @post.name))
        else
          flash[:post_error] = 'There was an error saving your post.'
        end
      end
    end
  end
  
end
