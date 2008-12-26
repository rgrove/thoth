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

module Thoth
  class Comment < Sequel::Model
    include Ramaze::Helper::Link

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

    is :notnaughty

    validates do
      presence_of :author, :message => 'Please enter your name.'
      presence_of :title,  :message => 'Please enter a title for this comment.'

      length_of :author, :maximum => 64,
          :message => 'Please enter a name under 64 characters.'
      length_of :author_url, :maximum => 255,
          :message => 'Please enter a shorter URL.'
      length_of :body, :maximum => 65536,
          :message => 'You appear to be writing a novel. Please try to keep ' <<
                      'it under 64K.'
      length_of :title, :maximum => 255,
          :message => 'Please enter a title shorter than 255 characters.'
    end

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
      reverse_order(:created_at).paginate(page, limit)
    end

    #--
    # Instance Methods
    #++

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
      redcloth = RedCloth.new(body, [:filter_styles])

      self[:body]          = body
      self[:body_rendered] = Sanitize.clean(redcloth.to_html(
        :refs_textile,
        :block_textile_lists,
        :inline_textile_link,
        :inline_textile_code,
        :glyphs_textile,
        :inline_textile_span
      ), CONFIG_SANITIZE)
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

    # Gets the post to which this comment is attached.
    def post
      @post ||= Post[post_id]
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
  end
end
