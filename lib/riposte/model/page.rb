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

class Page < Sequel::Model
  include Ramaze::Helper::Link
  include Ramaze::Helper::Wiki
  
  set_schema do
    primary_key :id
    
    varchar  :title,         :null => false, :unique => true
    varchar  :name,          :null => false, :unique => true
    text     :body,          :null => false
    text     :body_rendered, :null => false
    datetime :created_at,    :null => false
    datetime :updated_at,    :null => false
  end
  
  validates do
    presence_of :title, :message => 'Please enter a title for this page.'
    presence_of :name, :message => 'Please enter a name for this page.'
    presence_of :body, 
        :message => "Come on, I'm sure you can think of something to write."
    
    length_of :title, :maximum => 255,
        :message => 'Please enter a title under 255 characters.'
    length_of :name,  :maximum => 64,
        :message => 'Please enter a name under 64 characters.'
    
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

  def body=(body)
    self[:body]          = body.strip
    self[:body_rendered] = RedCloth.new(wiki_to_html(body.dup.strip)).to_html
  end
  
  # Gets the creation time of this page. If _format_ is provided, the time will
  # be returned as a formatted String. See Time.strftime for details.
  def created_at(format = nil)
    if new?
      format ? Time.now.strftime(format) : Time.now
    else
      format ? self[:created_at].strftime(format) : self[:created_at]
    end
  end
  
  def name=(name)
    self[:name] = name.strip unless name.nil?
  end
  
  def title=(title)
    self[:title] = title.strip unless title.nil?
  end
  
  # Gets the time this page was last updated. If _format_ is provided, the time
  # will be returned as a formatted String. See Time.strftime for details.
  def updated_at(format = nil)
    if new?
      format ? Time.now.strftime(format) : Time.now
    else
      format ? self[:updated_at].strftime(format) : self[:updated_at]
    end
  end

  # URL for this page.
  def url
    Riposte::Config.site.url.chomp('/') + R(PageController, name)
  end
end

Page.create_table unless Page.table_exists?
