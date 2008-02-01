class CommentsController < Ramaze::Controller
  engine :Erubis
  
  helper :admin
  helper :cache
  
  layout '/layout/main'

  if ENABLE_CACHE
    cache :index, :ttl => 30, :key => lambda { check_auth }
    cache :atom, :rss, :ttl => 60
  end

  def index
    now = Time.now.strftime('%Y%j')
    
    comments = Comment.recent.partition do |comment|
      comment.created_at('%Y%j') == now
    end

    @title   = 'Recent Comments'
    @today   = comments[0]
    @ancient = comments[1]
  end
  
  def atom
    response.header['Content-Type'] = 'application/atom+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    respond x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      comments_url = SITE_URL.chomp('/') + Rs()
      
      x.id       comments_url
      x.title    "#{SITE_NAME}: Recent Comments"
      x.subtitle SITE_DESCRIPTION
      x.updated  Time.now.rfc2822 # TODO: use modification time of the last post
      x.link     :href => comments_url
      x.link     :href => SITE_URL.chomp('/') + Rs(:atom), :rel => 'self'

      x.author {
        x.name  AUTHOR_NAME
        x.email AUTHOR_EMAIL
        x.uri   SITE_URL
      }

      Comment.recent.each do |comment|
        x.entry {
          x.id        comment.url
          x.title     comment.title, :type => 'html'
          x.published comment.created_at.xmlschema
          x.updated   comment.updated_at.xmlschema
          x.link      comment.url, :rel => 'alternate'
          x.content   comment.body_rendered, :type => 'html'
        }
      end
    }
  end
  
  def rss
    response.header['Content-Type'] = 'application/rss+xml'

    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!

    respond x.rss(:version => '2.0') {
      x.channel {
        x.title          "#{SITE_NAME}: Recent Comments"
        x.link           SITE_URL
        x.description    SITE_DESCRIPTION
        x.managingEditor "#{AUTHOR_EMAIL} (#{AUTHOR_NAME})"
        x.webMaster      "#{AUTHOR_EMAIL} (#{AUTHOR_NAME})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            30
        
        Comment.recent.each do |comment|
          x.item {
            x.title       comment.title
            x.link        comment.url
            x.author      comment.author
            x.guid        comment.url, :isPermaLink => 'true'
            x.pubDate     comment.created_at.rfc2822
            x.description comment.body_rendered
          }
        end
      }
    }
  end
  
end
