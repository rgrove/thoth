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

class Post < Sequel::Model
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
    presence_of :title, :message => 'Please enter a title for this post.'
    presence_of :body, :message => "What's the matter? Cat got your tongue?"
    
    length_of :title, :maximum => 255,
        :message => 'Please enter a title under 255 characters.'
    length_of :name, :maximum => 64,
        :message => 'Please enter a name under 64 characters.'
    
    # TODO: This should work according to the Sequel docs, but it doesn't.
    #true_for :title, :logic => lambda { !Post[:title => title] },
    #    :message => 'This title was already used for another post.'

    format_of :name, :with => /^[0-9a-z_-]+$/i,
        :message => 'Page names may only contain letters, numbers, ' +
                    'underscores, and dashes.'
  end
  
  before_create do
    self.created_at = Time.now
  end
  
  before_save do
    self.updated_at = Time.now
  end
  
  # Gets a paginated dataset of recent posts sorted in reverse order by creation
  # time.
  def dataset.recent(page = 1, limit = 10)
    reverse_order(:created_at).paginate(page, limit)
  end
  
  def body=(body)
    self[:body_rendered] = body.dup
    self[:body]          = body
  end
  
  # Gets the Post with the specified name, where +name+ can be either a name or
  # an id.
  def self.get(name)
    return Post[name] if name.is_a?(Numeric)
    
    name = name.to_s.strip.downcase
    
    if name =~ /^\d+$/
      Post[name]
    else
      Post[:name => name]
    end
  end

  # Comments attached to this Post, ordered by creation time.
  def comments
    Comment.filter(:post_id => id).order(:created_at)
  end
  
  def created_at(format = nil)
    if exists?
      format ? self[:created_at].strftime(format) : self[:created_at]
    else
      format ? Time.now.strftime(format) : Time.now
    end
  end

  # Tags attached to this Post, ordered by name.
  def tags
    if exists?
      Tag.filter(:id => TagsPostsMap.filter(:post_id => id).select(:tag_id)).
          order(:name).all
    else
      return @fake_tags || []
    end
  end
  
  def tags=(tag_names)
    if tag_names.is_a?(String)
      tag_names = tag_names.split(',', 64)
    elsif !tag_names.is_a?(Array)
      raise ArgumentError, "Expected String or Array, got #{tag_names.class}"
    end
    
    tag_names = tag_names.map{|n| n.strip.downcase}.uniq.delete_if{|n| n.empty?}

    if exists?
      real_tags = []
      
      # First delete any existing tag mappings for this post.
      TagsPostsMap.filter(:post_id => id).delete
      
      # Create new tags and new mappings.
      tag_names.each do |name|
        tag = Tag.find_or_create[:name => name]
        real_tags << tag
        TagsPostsMap.create(:post_id => id, :tag_id => tag.id)
      end

      return real_tags
    else
      # This Post hasn't been saved yet, so instead of attaching actual tags to
      # it, we'll create a bunch of fake tags just for the preview. We won't
      # create the real ones until the Post is saved.
      @fake_tags = []

      tag_names.each {|name| @fake_tags << Tag.new(:name => name) }
      @fake_tags.sort! {|a, b| a.name <=> b.name }

      return @fake_tags
    end
  end
  
  def title=(title)
    title.strip!
    
    # Set the post's name if it isn't already set.
    if self[:name].nil? || self[:name].empty?
      index = 1

      # Remove HTML entities and non-alphanumeric characters, replace spaces
      # with underscores, and truncate the name at 64 characters.
      name = title.strip.downcase.gsub(/&[^\s;]+;/, '_').
          gsub(/[^\s0-9a-z-]/, '').gsub(/\s+/, '_')[0..63]

      # Strip off any trailing non-alphanumeric characters.
      name.gsub!(/[_-]+$/, '')

      # Ensure that the name doesn't conflict with any methods on the Post
      # controller and that no two posts have the same name.
      while PostController.methods.include?(name) || 
            PostController.instance_methods.include?(name) ||
            Post[:name => name]
        
        if name[-1] == index
          name[-1] = (index += 1).to_s
        else
          name = name[0..62] if name.size >= 64
          name += (index += 1).to_s
        end
      end

      self[:name] = name
    end

    self[:title] = title
  end
  
  def updated_at(format = nil)
    if exists?
      format ? self[:updated_at].strftime(format) : self[:updated_at]
    else
      format ? Time.now.strftime(format) : Time.now
    end
  end

  # URL for this Post.
  def url
    Riposte::Config::SITE_URL.chomp('/') + R(PostController, name)
  end
end

unless Post.table_exists?
  Post.create_table
  Post.create(
    :title => 'Welcome to your new Riposte blog',
    :body  => %[
      <p>
        If you're reading this, you've successfully installed Riposte.
        Congratulations!
      </p>
      
      <p>
        Now you'll probably want to get started tweaking and customizing. The
        first thing to do, if you haven't already, is to rename
        <code>riposte.conf.sample</code> to <code>riposte.conf</code> and edit
        it to set up your blog. Be sure to change the administrator username and
        password, and remember that you need to restart Riposte in order for
        your changes to take effect.
      </p>
      
      <p>
        Once you've edited the config file to your liking, you can
        <a href="/admin">login</a> and begin creating blog posts and pages. You
        can also delete this post to make way for your own glorious words.
      </p>
      
      <p>
        Enjoy!
      </p>
    ].unindent
  )
end
