# = import_pantsphp.rb
#
# Reads an existing MySQL database from a Pants PHP installation and imports it
# into a new SQLite3 database.
#
# == Usage
#
#   # ruby import_pantsphp.rb mysql://user:pass@hostname/pants_db
#
# == Output
#
# The imported data will be written to +db/test.db+. That file will be
# overwritten if it already exists.
#

require 'rubygems'
require 'ramaze'
require 'sequel'

APP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
TEST_DB = File.join(APP_DIR, 'db', 'test.db')

# Check that we got a MySQL connection string arg.
if ARGV.empty? || !(ARGV[0] =~ /^mysql:\/\//i)
  abort "Invalid MySQL connection string."
end

# Delete /db/test.db if it exists.
if File.exist?(TEST_DB)
  begin
    File.delete(TEST_DB)
  rescue => e
    abort "Unable to delete #{TEST_DB}"
  end
end

require APP_DIR + '/config'

DB    = Sequel.open(DB_TEST)
MYSQL = Sequel.open(ARGV[0])

# Load models and controllers.
acquire "#{APP_DIR}/helper/*"
acquire "#{APP_DIR}/controller/*"
acquire "#{APP_DIR}/model/*"

# Disable model hooks.
class Comment
  def before_create; end
  def before_save; end
end

class Page
  def before_create; end
  def before_save; end
end

class Post
  def before_create; end
  def before_save; end
end

# Import pages.
puts 'Importing pages...'

MYSQL[:pages].each do |row|
  Page.new do |page|
    page.id         = row[:id]
    page.title      = row[:title]
    page.name       = row[:name]
    page.body       = row[:content]
    page.created_at = row[:posted]
    page.updated_at = row[:modified]
    
    if page.valid?
      page.save
    else
      p page.errors.full_messages
      exit
    end
  end
end

# Import posts.
puts 'Importing posts...'

MYSQL[:articles].each do |row|
  Post.new do |post|
    post.id         = row[:id]
    post.title      = row[:title]
    post.body       = row[:content]
    post.created_at = row[:posted]
    post.updated_at = row[:modified]
    
    if post.valid?
      post.save
    else
      p post.errors.full_messages
      exit
    end
  end
end

# Import tags.
puts 'Importing tags...'

MYSQL[:tags].each do |tag|
  DB[:tags] << {:id => tag[:id], :name => tag[:name]}
end

MYSQL[:tags_articles_map].each do |tagmap|
  DB[:tags_posts_map] << {:id => tagmap[:id], :tag_id => tagmap[:tag_id],
      :post_id => tagmap[:article_id]}
end

# Import comments.
puts 'Importing comments...'

MYSQL[:comments].each do |row|
  Comment.new do |comment|
    comment.id         = row[:id]
    comment.author     = row[:author]
    comment.author_url = row[:url]
    comment.title      = row[:title]
    comment.body       = row[:content]
    comment.created_at = row[:posted]
    comment.updated_at = row[:posted]
    comment.post_id    = row[:article_id]
    
    if comment.valid?
      comment.save
    else
      p comment.errors.full_messages
    end
  end
end

puts 'Done'
