#
# Thoth -> Thoth importer (for moving content to a different database).
#

class ThothImporter < Thoth::Importer

  before_import do
    unless uri = ARGV.shift
      puts "Please enter a connection string for the Thoth database you want to import."
      puts "Example: mysql://user:pass@localhost/dbname"
      print "> "

      uri = STDIN.gets.strip
      puts
    end

    begin
      @source = Sequel.connect(uri)
    rescue => e
      abort("Error: unable to connect to database: #{e}")
    end
  end

  import_comments do
    @source[:comments].each do |row|
      Thoth::Comment.create do |comment|
        comment.id            = row[:id]
        comment.author        = row[:author]
        comment.author_url    = row[:author_url]
        comment.author_email  = row[:author_email] || 'noemail@noemail.com'
        comment.title         = row[:title]
        comment.body          = row[:body]
        comment.body_rendered = row[:body_rendered]
        comment.ip            = row[:ip]
        comment.created_at    = row[:created_at]
        comment.updated_at    = row[:updated_at]
        comment.post_id       = row[:post_id]
        comment.deleted       = row[:deleted]
      end
    end
  end

  import_pages do
    @source[:pages].each do |row|
      Thoth::Page.create do |page|
        page.id            = row[:id]
        page.title         = row[:title]
        page.name          = row[:name]
        page.body          = row[:body]
        page.body_rendered = row[:body_rendered]
        page.created_at    = row[:created_at]
        page.updated_at    = row[:updated_at]
      end
    end
  end

  import_posts do
    @source[:posts].each do |row|
      Thoth::Post.create do |post|
        post.id             = row[:id]
        post.title          = row[:title]
        post.name           = row[:name]
        post.body           = row[:body]
        post.body_rendered  = row[:body_rendered]
        post.is_draft       = row[:is_draft]
        post.created_at     = row[:created_at]
        post.updated_at     = row[:updated_at]
        post.allow_comments = row[:allow_comments]
      end
    end
  end

  import_tags do
    @source[:tags].each do |tag|
      Thoth.db[:tags] << {
        :id   => tag[:id],
        :name => tag[:name]
      }
    end

    @source[:tags_posts_map].each do |tagmap|
      Thoth.db[:tags_posts_map] << {
        :id      => tagmap[:id],
        :tag_id  => tagmap[:tag_id],
        :post_id => tagmap[:post_id]
      }
    end
  end

  import_media do
    @source[:media].each do |row|
      Thoth::Media.create do |media|
        media.id         = row[:id]
        media.filename   = row[:filename]
        media.mimetype   = row[:mimetype]
        media.size       = row[:size]
        media.created_at = row[:created_at]
        media.updated_at = row[:updated_at]
      end
    end
  end

end
