#--
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
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

require 'digest/md5'
require 'strscan'

module Thoth
  class Comment < Sequel::Model
    plugin :hook_class_methods
    plugin :validation_helpers

    CONFIG_SANITIZE = {
      :elements => [
        'a', 'b', 'blockquote', 'br', 'code', 'dd', 'dl', 'dt', 'em', 'i',
        'li', 'ol', 'p', 'pre', 'small', 'strike', 'strong', 'sub', 'sup',
        'u', 'ul'
      ],

      :attributes => {
        'a'   => ['href', 'title'],
        'pre' => ['class']
      },

      :add_attributes => {'a' => {'rel' => 'nofollow'}},
      :protocols => {'a' => {'href' => ['ftp', 'http', 'https', 'mailto']}}
    }

    before_create do
      self.created_at = Time.now
    end

    before_save do
      self.updated_at = Time.now
    end

    #--
    # Class Methods
    #++

    # Recently-posted comments (up to _limit_) sorted in reverse order by
    # creation time.
    def self.recent(page = 1, limit = 10)
      filter(:deleted => false).reverse_order(:created_at).paginate(page, limit)
    end

    #--
    # Instance Methods
    #++

    def author=(author)
      self[:author] = author.strip unless author.nil?
    end

    def author_email=(email)
      @gravatar_url = nil
      self[:author_email] = email.strip unless email.nil?
    end

    def author_url=(url)
      self[:author_url] = url.strip unless url.nil?
    end

    def body=(body)
      redcloth = RedCloth.new(body, [:filter_styles])

      self[:body]          = body
      self[:body_rendered] = insert_breaks(Sanitize.clean(redcloth.to_html(
        :refs_textile,
        :block_textile_lists,
        :inline_textile_link,
        :inline_textile_code,
        :glyphs_textile,
        :inline_textile_span
      ), CONFIG_SANITIZE))
    end

    # Gets the creation time of this comment. If _format_ is provided, the time
    # will be returned as a formatted String. See Time.strftime for details.
    def created_at(format = nil)
      if new?
        format ? Time.now.strftime(format) : Time.now
      else
        format ? self[:created_at].strftime(format) : self[:created_at]
      end
    end

    # Gets the Gravatar URL for this comment.
    def gravatar_url
      return @gravatar_url if @gravatar_url

      md5     = Digest::MD5.hexdigest((author_email || author).downcase)
      default = CGI.escape(Config.site['gravatar']['default'])
      rating  = Config.site['gravatar']['rating']
      size    = Config.site['gravatar']['size']

      @gravatar_url = "http://www.gravatar.com/avatar/#{md5}.jpg?d=#{default}&r=#{rating}&s=#{size}"
    end

    # Gets the post to which this comment is attached.
    def post
      @post ||= Post[post_id]
    end

    def relative_url
      new? ? '#' : "#comment-#{id}"
    end

    def title=(title)
      self[:title] = title.strip unless title.nil?
    end

    # Gets the time this comment was last updated. If _format_ is provided, the
    # time will be returned as a formatted String. See Time.strftime for details.
    def updated_at(format = nil)
      if new?
        format ? Time.now.strftime(format) : Time.now
      else
        format ? self[:updated_at].strftime(format) : self[:updated_at]
      end
    end

    # URL for this comment.
    def url
      new? ? '#' : post.url + "#comment-#{id}"
    end

    def validate
      validates_presence(:author, :message => 'Please enter your name.')
      validates_presence(:title,  :message => 'Please enter a title for this comment.')

      validates_max_length(64,    :author,       :message => 'Please enter a name under 64 characters.')
      validates_max_length(255,   :author_email, :message => 'Please enter a shorter email address.')
      validates_max_length(255,   :author_url,   :message => 'Please enter a shorter URL.')
      validates_max_length(65536, :body,         :message => 'You appear to be writing a novel. Please try to keep it under 64K.')
      validates_max_length(150,   :title,        :message => 'Please enter a title shorter than 150 characters.')

      validates_format(/[^\s@]+@[^\s@]+\.[^\s@]+/,    :author_email, :message => 'Please enter a valid email address.')
      validates_format(/^(?:$|https?:\/\/\S+\.\S+)/i, :author_url,   :message => 'Please enter a valid URL or leave the URL field blank.')
    end

    protected

    # Inserts <wbr /> tags in long strings without spaces, while being careful
    # not to break HTML tags.
    def insert_breaks(str, length = 30)
      scanner = StringScanner.new(str)

      char    = ''
      count   = 0
      in_tag  = 0
      new_str = ''

      while char = scanner.getch do
        case char
        when '<'
          in_tag += 1

        when '>'
          in_tag -= 1
          in_tag = 0 if in_tag < 0

        when /\s/
          count = 0 if in_tag == 0

        else
          if in_tag == 0
            if count == length
              new_str << '<wbr />'
              count = 0
            end

            count += 1
          end
        end

        new_str << char
      end

      return new_str
    end

  end
end
