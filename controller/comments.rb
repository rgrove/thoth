class CommentsController < Ramaze::Controller
  engine :Erubis
  helper :cache
  layout '/layout/main'

  cache :index, :ttl => 30 if ENABLE_CACHE

  def index
    now = Time.now.strftime('%Y%j')
    
    comments = Comment.recent.partition do |comment|
      comment.created_at('%Y%j') == now
    end

    @title   = 'Recent Comments'
    @today   = comments[0]
    @ancient = comments[1]
  end
  
end
