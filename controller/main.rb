class MainController < Ramaze::Controller
  engine :Erubis

  helper :admin
  helper :cache
  helper :error
  helper :partial
  helper :redirect
  helper :ysearch

  layout '/layout/main'
  
  if ENABLE_CACHE
    cache :index, :atom, :rss, :ttl => 60, :key => lambda { check_auth }
  end

  def index
    @title    = SITE_NAME
    @posts    = Post.recent
    @next_url = @posts.next_page ? Rs(:archive, @posts.next_page) : nil
  end
  
  def atom
    response.header['Content-Type'] = 'application/atom+xml'
    
    x = Builder::XmlMarkup.new(:indent => 2)
    x.instruct!
    
    respond x.feed(:xmlns => 'http://www.w3.org/2005/Atom') {
      x.id       SITE_URL
      x.title    SITE_NAME
      x.subtitle SITE_DESCRIPTION
      x.updated  Time.now.rfc2822 # TODO: use modification time of the last post
      x.link     :href => SITE_URL
      x.link     :href => SITE_URL.chomp('/') + Rs(:atom), :rel => 'self'
      
      x.author {
        x.name  AUTHOR_NAME
        x.email AUTHOR_EMAIL
        x.uri   SITE_URL
      }
      
      Post.recent.each do |post|
        post_url = SITE_URL.chomp('/') + post.url
        
        x.entry {
          x.id        post_url
          x.title     post.title, :type => 'html'
          x.published post.created_at.xmlschema
          x.updated   post.updated_at.xmlschema
          x.link      post_url, :rel => 'alternate'
          x.content   post.body_rendered, :type => 'html'
          
          post.tags.each do |tag|
            x.category :term => tag.name, :label => tag.name,
                :scheme => SITE_URL.chomp('/') + tag.url
          end
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
        x.title          SITE_NAME
        x.link           SITE_URL
        x.description    SITE_DESCRIPTION
        x.managingEditor "#{AUTHOR_EMAIL} (#{AUTHOR_NAME})"
        x.webMaster      "#{AUTHOR_EMAIL} (#{AUTHOR_NAME})"
        x.docs           'http://backend.userland.com/rss/'
        x.ttl            60
        
        Post.recent.each do |post|
          post_url = SITE_URL.chomp('/') + post.url
          
          x.item {
            x.title       post.title
            x.link        post_url
            x.guid        post_url, :isPermaLink => 'true'
            x.pubDate     post.created_at.rfc2822
            x.description post.body_rendered
            
            post.tags.each do |tag|
              x.category tag.name, :domain => SITE_URL.chomp('/') + tag.url
            end
          }
        end
      }
    }
  end
  
  # Legacy redirect.
  def archives(page = 1)
    redirect R(ArchiveController, page), :status => 301
  end
  
  # Legacy redirect.
  def article(name)
    redirect R(PostController, name), :status => 301
  end
  
  # TODO: recent-comments redirect
end
