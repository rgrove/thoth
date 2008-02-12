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

require 'rubygems'
require 'hpricot'

require 'helper/sanitize'

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

    length_of :author, :maximum => 64,
        :message => 'Please enter a name under 64 characters.'
    length_of :author_url, :maximum => 255,
        :message => 'Please enter a shorter URL.'
    length_of :body, :maximum => 65536,
        :message => 'You appear to be writing a novel. Please try to keep it ' +
                    'under 64K.'
    length_of :title, :maximum => 255,
        :message => 'Please enter a title shorter than 255 characters.'
  end
  
  before_create do
    self.created_at = Time.now
  end
  
  before_save do
    self.updated_at = Time.now
  end
  
  # Recently-posted comments (up to +limit+) sorted in reverse order by creation
  # time.
  def dataset.recent(page = 1, limit = 10)
    reverse_order(:created_at).paginate(page, limit)
  end
  
  def author=(author)
    self[:author] = author.strip unless author.nil?
  end
  
  def author_url=(url)
    # Ensure that the URL begins with a valid protocol.
    unless url.nil? || url.empty? || url =~ /^(?:https?|mailto):\/\//i
      url = 'http://' + url
    end

    self[:author_url] = url.strip unless url.nil?
  end

  def body=(body)
    body          = sanitize_html(body.strip)
    body_rendered = body.dup.strip
    
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
    if new?
      format ? Time.now.strftime(format) : Time.now
    else
      format ? self[:created_at].strftime(format) : self[:created_at]
    end
  end
  
  # Post to which this comment is attached.
  def post
    @post ||= Post[post_id]
  end
  
  def title=(title)
    self[:title] = title.strip unless title.nil?
  end
  
  def updated_at(format = nil)
    if new?
      format ? Time.now.strftime(format) : Time.now
    else
      format ? self[:updated_at].strftime(format) : self[:updated_at]
    end
  end

  # URL for this comment.
  def url
    if new?
      '#'
    else
      Riposte::Config.site.url.chomp('/') + R(PostController, post_id) +
          "#comment-#{id}"
    end
  end
end

Comment.create_table unless Comment.table_exists?
