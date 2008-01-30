class Tag < Sequel::Model
  include Ramaze::CgiHelper
  include Ramaze::LinkHelper

  set_schema do
    primary_key :id
    varchar :name, :null => false, :unique => true
    unique :name
  end
  
  validates do
    presence_of :name
    length_of :name, :maximum => 64
  end
  
  # Posts attached to this Tag.
  def posts
    Post.filter(:id => TagsPostsMap.filter(:tag_id => id).select(:post_id)).
        reverse_order(:created_at)
  end
  
  # Relative URL for this tag (e.g., +/tag/foo+).
  def relative_url
    R(TagController, u(name))
  end
  
  # Absolute URL for this tag (e.g., +http://example.com/tag/foo+).
  def url
    SITE_URL.chomp('/') + relative_url
  end
end

Tag.create_table unless Tag.table_exists?
