class Page < Sequel::Model
  include Ramaze::LinkHelper
  
  set_schema do
    primary_key :id
    
    varchar  :title,         :null => false, :unique => true
    varchar  :name,          :null => false, :unique => true
    text     :body,          :null => false
    text     :body_rendered, :null => false
    datetime :created_at,    :null => false
    datetime :updated_at,    :null => false
    
    unique :name
  end
  
  validates do
    presence_of :title, :message => 'Please enter a title for this page.'
    presence_of :name,  :message => 'Please enter a name for this page.'
    presence_of :body,  :message => "Come on, I'm sure you can think of something to write."
    
    length_of :title, :maximum => 255, :message => 'Please enter a title under 255 characters.'
    length_of :name,  :maximum => 64,  :message => 'Please enter a name under 64 characters.'
    
    format_of :name, :with => /^[0-9a-z_-]+$/i, :message => 'Post names may only contain letters, numbers, underscores, and dashes.'
  end
  
  before_create do
    self.created_at = Time.now
  end
  
  before_save do
    self.updated_at = Time.now
  end
  
  def body=(body)
    body_rendered = body.dup
    
    # Parse wiki-style links to other pages.
    body_rendered.gsub!(/\[\[([0-9a-z_-]+)\|(.+?)\]\]/i) do
      A($2, :href => R(PageController, $1.downcase))
    end
    body_rendered.gsub!(/\[\[([0-9a-z_-]+)\]\]/i) do
      A($1, :href => R(PageController, $1.downcase))
    end
    
    # Parse wiki-style links to articles.
    body_rendered.gsub!(/\[\[@(\d+|[0-9a-z_-]+)\|(.+?)\]\]/i) do
      A($2, :href => R(PostController, $1.downcase))
    end
    body_rendered.gsub!(/\[\[@(\d+|[0-9a-z_-]+)\]\]/i) do
      A($1, :href => R(PostController, $1.downcase))
    end

    self[:body_rendered] = body_rendered
    self[:body]          = body
  end
  
  # Relative URL for this Page (e.g., +/page/foo+).
  def relative_url
    R(PageController, name)
  end
  
  # Absolute URL for this Page (e.g., +http://example.com/page/foo+).
  def url
    SITE_URL.chomp('/') + relative_url
  end
end

Page.create_table unless Page.table_exists?
