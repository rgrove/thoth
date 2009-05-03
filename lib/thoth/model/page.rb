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
  class Page < Sequel::Model
    include Thoth::Helper::Wiki

    plugin :hook_class_methods
    plugin :validation_helpers

    after_destroy do
      Page.normalize_positions
    end

    before_create do
      self.created_at = Time.now
    end

    before_save do
      self.updated_at = Time.now
    end

    set_restricted_columns :position

    #--
    # Class Methods
    #++

    # Returns true if the specified page name is already taken or is a reserved
    # name.
    def self.name_unique?(name)
      !PageController.methods.include?(name) &&
          !PageController.instance_methods.include?(name) &&
          !Page[:name => name.to_s.downcase]
    end

    # Returns true if the specified page name consists of valid characters and
    # is not too long or too short.
    def self.name_valid?(name)
      !!(name =~ /^[0-9a-z_-]{1,64}$/i)
    end

    # Adjusts the position values of all pages, resolving duplicate positions
    # and eliminating gaps.
    def self.normalize_positions
      db.transaction do
        i = 1

        order(:position).all do |page|
          unless page.position == i
            filter(:id => page.id).update(:position => i)
          end

          i += 1
        end
      end
    end

    # Sets the display position of the specified page, adjusting the position of
    # other pages as necessary.
    def self.set_position(page, pos)
      unless page.is_a?(Page) || page = Page[page.to_i]
        raise ArgumentError, "Invalid page id: #{page}"
      end

      pos     = pos.to_i
      cur_pos = page.position

      unless pos > 0
        raise ArgumentError, "Invalid position: #{pos}"
      end

      db.transaction do
        if pos < cur_pos
          filter{:position >= pos && :position < cur_pos}.
              update(:position => 'position + 1'.lit)
        elsif pos > cur_pos
          filter{:position > cur_pos && :position <= pos}.
              update(:position => 'position - 1'.lit)
        end

        filter(:id => page.id).update(:position => pos)
      end
    end

    # Returns a valid, unique page name based on the specified title. If the
    # title is empty or cannot be converted into a valid name, an empty string
    # will be returned.
    def self.suggest_name(title)
      index = 1

      # Remove HTML entities and non-alphanumeric characters, replace spaces
      # with hyphens, and truncate the name at 64 characters.
      name = title.to_s.strip.downcase.gsub(/&[^\s;]+;/, '_').
          gsub(/[^\s0-9a-z-]/, '').gsub(/\s+/, '-')[0..63]

      # Strip off any trailing non-alphanumeric characters.
      name.gsub!(/[_-]+$/, '')

      return '' if name.empty?

      # Ensure that the name doesn't conflict with any methods on the Page
      # controller and that no two pages have the same name.
      until self.name_unique?(name)
        if name[-1] == index
          name[-1] = (index += 1).to_s
        else
          name = name[0..62] if name.size >= 64
          name += (index += 1).to_s
        end
      end

      return name
    end

    #--
    # Instance Methods
    #++

    def body=(body)
      self[:body]          = body.strip
      self[:body_rendered] = RedCloth.new(wiki_to_html(body.dup.strip)).to_html
    end

    # Gets the creation time of this page. If _format_ is provided, the time
    # will be returned as a formatted String. See Time.strftime for details.
    def created_at(format = nil)
      if new?
        format ? Time.now.strftime(format) : Time.now
      else
        format ? self[:created_at].strftime(format) : self[:created_at]
      end
    end

    def name=(name)
      self[:name] = name.strip.downcase unless name.nil?
    end

    def title=(title)
      title.strip!

      # Set the page name if it isn't already set.
      if self[:name].nil? || self[:name].empty?
        self[:name] = Page.suggest_name(title)
      end

      self[:title] = title
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
      Config.site['url'].chomp('/') + PageController.r(:/, name).to_s
    end

    def validate
      validates_presence(:name,  :message => 'Please enter a name for this page.')
      validates_presence(:title, :message => 'Please enter a title for this page.')
      validates_presence(:body,  :message => "Come on, I'm sure you can think of something to write.")

      validates_max_length(255, :title, :message => 'Please enter a title under 255 characters.')
      validates_max_length(64,  :name,  :message => 'Please enter a name under 64 characters.')

      validates_format(/^[0-9a-z_-]+$/i, :name, :message => 'Page names may only contain letters, numbers, underscores, and dashes.')
    end

  end
end
