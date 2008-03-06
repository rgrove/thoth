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

module Riposte
  class Importer 
    class << self

      def after_import(&block)    trait[:after]    = block; end
      def before_import(&block)   trait[:before]   = block; end
      def import_comments(&block) trait[:comments] = block; end
      def import_media(&block)    trait[:media]    = block; end
      def import_pages(&block)    trait[:pages]    = block; end
      def import_posts(&block)    trait[:posts]    = block; end
      def import_tags(&block)     trait[:tags]     = block; end
    
      def load_importer(name)
        importer = name.to_s.downcase.strip.gsub(/importer$/, '')
        files    = Dir["{#{HOME_DIR/:importer},#{LIB_DIR/:importer},#{$:.join(',')}}/#{importer}.rb"]

        unless (files.any? && require(files.first)) || require(importer)
          raise LoadError, "Importer #{name} not found"
        end
      
        Kernel.const_get("#{importer.capitalize}Importer")
      end
    
      def run
        # Bootstrap.
        Ramaze::Log.loggers = []
        Riposte.open_db

        acquire LIB_DIR/:helper/'*'
        acquire LIB_DIR/:controller/'*'
        acquire LIB_DIR/:model/'*'
      
        # Disable model hooks.
        [Comment, Media, Page, Post].each do |klass|
          klass.class_eval('def before_create; end')
          klass.class_eval('def before_save; end')
        end

        # Confirm that the user really wants to blow away their database.
        puts "WARNING: Your existing Riposte database will be completely erased to make way"
        puts "for the imported content. Are you sure you want to continue? (y/n) "
        print "> "
        
        exit unless STDIN.gets.strip =~ /^y(?:es)?/i
        puts

        trait[:before].call if trait[:before]

        if trait[:pages]
          puts 'Importing pages...'
        
          Riposte.db.transaction do
            Page.delete
            trait[:pages].call
          end
        end
      
        if trait[:posts]
          puts 'Importing blog posts...'

          Riposte.db.transaction do
            Post.delete
            trait[:posts].call
          end
        end
      
        if trait[:tags]
          puts 'Importing tags...'

          Riposte.db.transaction do
            Tag.delete
            TagsPostsMap.delete
            trait[:tags].call
          end
        end
      
        if trait[:comments]
          puts 'Importing comments...'

          Riposte.db.transaction do
            Comment.delete
            trait[:comments].call
          end
        end
      
        if trait[:media]
          puts 'Importing media...'

          Riposte.db.transaction do
            Media.delete
            trait[:media].call
          end
        end
      
        trait[:after].call if trait[:after]
      end

    end
  end
end
