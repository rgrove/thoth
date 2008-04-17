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

class CreateSchema < Sequel::Migration
  def down
    drop_table :comments, :media, :pages, :posts, :tags, :tags_posts_map
  end

  def up
    unless table_exists?(:comments)
      create_table :comments do
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
    end

    unless table_exists?(:media)
      create_table :media do
        primary_key :id

        varchar  :filename,   :null => false, :unique => true
        varchar  :mimetype,   :null => false
        datetime :created_at, :null => false
        datetime :updated_at, :null => false
      end
    end

    unless table_exists?(:pages)
      create_table :pages do
        primary_key :id

        varchar  :title,         :null => false, :unique => true
        varchar  :name,          :null => false, :unique => true
        text     :body,          :null => false
        text     :body_rendered, :null => false
        datetime :created_at,    :null => false
        datetime :updated_at,    :null => false
      end
    end

    unless table_exists?(:posts)
      create_table :posts do
        primary_key :id

        varchar  :title,         :null => false, :unique => true
        varchar  :name,          :null => false, :unique => true
        text     :body,          :null => false
        text     :body_rendered, :null => false
        datetime :created_at,    :null => false
        datetime :updated_at,    :null => false
      end
    end
    
    unless table_exists?(:tags)
      create_table :tags do
        primary_key :id
        varchar :name, :null => false, :unique => true
      end
    end

    unless table_exists?(:tags_posts_map)
      create_table :tags_posts_map do
        primary_key :id

        foreign_key :post_id, :table => :posts
        foreign_key :tag_id,  :table => :tags

        unique([:post_id, :tag_id])
      end
    end
  end
end
