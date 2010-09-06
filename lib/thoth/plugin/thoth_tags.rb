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

module Thoth; module Plugin

  # Tags plugin for Thoth.
  module Tags

    Config << {
      'tags' => {

        # Time in seconds to cache tag data. It's a good idea to keep this nice
        # and high to improve the performance of your site. Default is 1800
        # seconds (30 minutes).
        'cache_ttl' => 1800

      }
    }

    class << self

      # Gets an Array of the most heavily-used tags. The first element of the
      # array is a Tag object, the second element is the number of times it's
      # used.
      def top_tags(limit = 10)
        cache = Ramaze::Cache.plugin

        if tags = cache["top_tags_#{limit}"]
          return tags
        end

        tags    = []
        tag_ids = TagsPostsMap.group(:tag_id).select(:tag_id => :tag_id,
            :COUNT[:tag_id] => :count).reverse_order(:count).limit(limit)

        tag_ids.all {|row| tags << [Tag[row[:tag_id]], row[:count]] }
        cache.store("top_tags_#{limit}", tags, :ttl => Config.tags['cache_ttl'])
      end

      def tag_cloud(classes, count = 20)
        # Implementation adapted from
        # http://juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/

        cache = Ramaze::Cache.plugin

        unless tags = cache["tag_cloud_#{count}"]
          tags    = []
          tag_ids = TagsPostsMap.group(:tag_id).select(:tag_id => :tag_id,
                 :COUNT[:tag_id] => :count).reverse_order(:count).limit(count)
          tag_ids.all {|row| tags << Tag[row[:tag_id]] }
          tags = tags.sort_by {|tag| tag.name }
          cache.store("tag_cloud_#{count}", tags, :ttl => Config.tags['cache_ttl'])
        end

        max, min = 0, 0
        tags = top_tags(count)
        tags.each do |tag, count|
          max = count if count > max
          min = count if count < min
        end

        divisor = ((max - min) / classes.size) + 1

        tags.each do |tag, count|
          yield tag, classes[(count - min) / divisor]
        end
      end

    end
  end

end; end
