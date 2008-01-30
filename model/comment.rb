require 'rubygems'
require 'hpricot'

class Comment < Sequel::Model
  include Ramaze::LinkHelper
  include Ramaze::SanitizeHelper
  
  set_schema do
    primary_key :id
    
    varchar  :author,        :null => false
    varchar  :author_url
    varchar  :title,         :null => false
    text     :body,          :default => ''
    text     :body_rendered, :default => ''
    varchar  :ip
    datetime :created_at,    :null => false
    datetime :updated_at,    :null => false

    foreign_key :post_id, :table => :posts
    index :post_id
  end
  
  validates do
    presence_of :author, :message => 'Please enter your name.'
    presence_of :title,  :message => 'Please enter a title for this comment.'

    length_of :author,     :maximum => 64,    :message => 'Please enter a name under 64 characters.'
    length_of :author_url, :maximum => 255,   :message => 'Please enter a shorter URL.'
    length_of :body,       :maximum => 65536, :message => 'You appear to be writing a novel. Please try to keep it under 64K.'
    length_of :title,      :maximum => 255,   :message => 'Please enter a title shorter than 255 characters.'
  end
  
  before_create do
    self.created_at = Time.now
  end
  
  before_save do
    self.updated_at = Time.now
  end
  
  # Recently-posted comments (up to +limit+) sorted in reverse order by creation
  # time.
  def dataset.recent(limit = 10)
    order(:created_at.desc).limit(limit)
  end
  
  def author_url=(url)
    # Ensure that the URL begins with a valid protocol.
    unless url.nil? || url.empty? || url =~ /^(?:https?|mailto):\/\//i
      url = 'http://' + url
    end

    self[:author_url] = url
  end

  def body=(body)
    body          = sanitize_html(body)
    body_rendered = body.dup
    
    # Autoformat the comment body if necessary.
    unless body_rendered =~ /<p>/i || body_rendered =~ /(?:<br\s*\/?>\s*){2,}/i
      body_rendered.gsub!(/\s*([\w\W]+?)(?:\n{2,}|(?:\r\n){2,}|\z)/) do |match|
        if match =~ /<(?:address|blockquote|dl|h[1-6]|ol|pre|table|ul)>/i
          match
        else
          "<p>#{match}</p>"
        end
      end
    end
    
    self[:body_rendered] = body_rendered
    self[:body]          = body
  end
  
  def created_at(format = nil)
    format ? self[:created_at].strftime(format) : self[:created_at]
  end
  
  # Post to which this comment is attached.
  def post
    @post ||= Post[post_id]
  end
  
  # Relative URL for this comment (e.g., +/post/42#comment-204).
  def relative_url
    R(PostController, post_id) + "#comment-#{id}"
  end
  
  def updated_at(format = nil)
    format ? self[:updated_at].strftime(format) : self[:updated_at]
  end
  
  # Absolute URL for this comment (e.g.,
  # +http://example.com/post/42#comment-204+).
  def url
    SITE_URL.chomp('/') + relative_url
  end
end

Comment.create_table unless Comment.table_exists?
