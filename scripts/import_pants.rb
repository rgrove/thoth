#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

# = import_pants.rb
#
# Connects to a Pants MySQL database and imports it into a Riposte database.
#
# == Usage
#
#   # ruby import_pants.rb mysql://user:pass@hostname/pants_db [connection uri]
#
# == Output
#
# The imported data will be written to the database named in the second
# connection string argument. The original Pants database will not be modified
# in any way.
#

require 'rubygems'
require 'ramaze'
require 'sequel'

APP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))

# Append the Riposte /lib directory to the include path if it's not there
# already.
$:.unshift(File.join(APP_DIR, 'lib'))
$:.uniq!

require 'riposte/config'

Riposte::Config.load_config(File.join(APP_DIR, 'riposte.conf'))

# Check that we got a MySQL connection string arg.
if ARGV.empty? || !(ARGV[0] =~ /^mysql:\/\//i)
  abort "Invalid MySQL connection string."
end

# Check that we got a second arg.
unless ARGV[1]
  abort "No output DB specified."
end

DB    = Sequel.open(ARGV[1])
MYSQL = Sequel.open(ARGV[0])

# Load models and controllers.
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

DB.transaction do
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
end

# Import posts.
puts 'Importing posts...'

DB.transaction do
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
end

# Import tags.
puts 'Importing tags...'

DB.transaction do
  MYSQL[:tags].each do |tag|
    DB[:tags] << {:id => tag[:id], :name => tag[:name]}
  end

  MYSQL[:tags_articles_map].each do |tagmap|
    DB[:tags_posts_map] << {:id => tagmap[:id], :tag_id => tagmap[:tag_id],
        :post_id => tagmap[:article_id]}
  end
end

# Import comments.
puts 'Importing comments...'

DB.transaction do
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
end

puts 'Done'
