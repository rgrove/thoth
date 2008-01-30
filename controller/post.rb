class PostController < Ramaze::Controller
  engine :Erubis
  
  helper :error
  helper :partial

  layout '/layout/main'
  
  def index(name = nil)
    error_404 unless name && @post = get_post(name)
    @title = @post.title    

    # Get form cookies.
    @author     = request.cookies['author']     || ''
    @author_url = request.cookies['author_url'] || ''
  end
  
  def comment(name)
    error_404 unless @post = get_post(name)
    @title = @post.title

    if request.post?
      # Dump the request if the robot traps were triggered.
      error_404 unless request['captcha'].empty? && request['comment'].empty?
      
      # Create a new comment.
      comment = Comment.new(
        :post_id    => @post.id,
        :author     => request[:author],
        :author_url => request[:author_url],
        :title      => request[:title],
        :body       => request[:body],
        :ip         => request.ip
      )
      
      # Set cookies.
      expire = Time.now + 315360000 # expire in 10 years

      response.set_cookie(:author, :expires => expire,
          :path => Rs(), :value => comment.author)
      response.set_cookie(:author_url, :expires => expire,
          :path => Rs(), :value => comment.author_url)
      
      if request[:action] == 'Preview Comment' || !comment.valid?
        @preview = comment
      elsif request[:action] == 'Post Comment'
        comment.save
      end
      
      @author     = comment.author
      @author_url = comment.author_url
    else
      # Get form cookies.
      @author     = request.cookies['author']     || ''
      @author_url = request.cookies['author_url'] || ''
    end
    
    render_template(:index)
  end

  private
  
  # Gets the Post with the specified +name+, where +name+ can be either a name
  # or an id.
  def get_post(name)
    name = name.strip.downcase
    
    if name =~ /^\d+$/
      # Look up post by id.
      return Post[name]
    else
      # Look up post by name.
      return Post[:name => name]
    end
  end
end
