class TagsPostsMap < Sequel::Model(:tags_posts_map)
  set_schema do
    primary_key :id
    
    foreign_key :post_id, :table => :posts
    foreign_key :tag_id,  :table => :tags
    
    unique([:post_id, :tag_id])
  end
  
  # Gets the Post associated with this mapping.
  def post
    Post[post_id]
  end
  
  # Gets the Tag associated with this mapping.
  def tag
    Tag[tag_id]
  end
end

TagsPostsMap.create_table unless TagsPostsMap.table_exists?
