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

module Thoth
  class Tag < Sequel::Model
    plugin :validation_helpers

    one_to_many  :tags_posts_map, :class => 'Thoth::TagsPostsMap'
    many_to_many :posts, :class => 'Thoth::Post',
        :join_table => :tags_posts_map, :read_only => true

    #--
    # Class Methods
    #++

    # Gets an array of tag names and post counts for tags with names that begin
    # with the specified query string.
    def self.suggest(query, limit = 1000)
      tags = []

      self.dataset.grep(:name, "#{query}%").all do |tag|
        tags << [tag.name, tag.posts.count]
      end

      tags.sort!{|a, b| b[1] <=> a[1]}
      tags[0, limit]
    end

    #--
    # Instance Methods
    #++

    # Gets the Atom feed URL for this tag.
    def atom_url
      Config.site['url'].chomp('/') + TagController.r(:atom, name).to_s
    end

    # Gets published posts with this tag.
    def posts
      @posts ||= posts_dataset.filter(:is_draft => false).reverse_order(
          :created_at)
    end

    # URL for this tag.
    def url
      Config.site['url'].chomp('/') + TagController.r(:/, name).to_s
    end

    def validate
      validates_presence(:name)
      validates_max_length(64, :name)
    end

  end
end
