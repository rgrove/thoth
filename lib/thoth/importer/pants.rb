#
# Pants -> Thoth importer.
#

class PantsImporter < Thoth::Importer

  before_import do
    unless uri = ARGV.shift
      puts "Please enter a connection string for the Pants database you want to import."
      puts "Example: mysql://user:pass@localhost/dbname"
      print "> "

      uri = STDIN.gets.strip
      puts
    end

    begin
      @pants = Sequel.open(uri)
    rescue => e
      abort("Error: unable to connect to database: #{e}")
    end
  end

  import_comments do
    @pants[:comments].each do |row|
      Comment.create do |comment|
        comment.id         = row[:id]
        comment.author     = row[:author]
        comment.author_url = row[:url]
        comment.title      = row[:title]
        comment.body       = row[:content]
        comment.created_at = row[:posted]
        comment.updated_at = row[:posted]
        comment.post_id    = row[:article_id]
      end
    end
  end

  import_pages do
    @pants[:pages].each do |row|
      Page.create do |page|
        page.id         = row[:id]
        page.title      = row[:title]
        page.name       = row[:name]
        page.body       = row[:content]
        page.created_at = row[:posted]
        page.updated_at = row[:modified]
      end
    end
  end

  import_posts do
    @pants[:articles].each do |row|
      Post.create do |post|
        post.id         = row[:id]
        post.title      = row[:title]
        post.body       = row[:content]
        post.created_at = row[:posted]
        post.updated_at = row[:modified]
      end
    end
  end

  import_tags do
    @pants[:tags].each do |tag|
      Thoth.db[:tags] << {
        :id   => tag[:id],
        :name => tag[:name].downcase
      }
    end

    @pants[:tags_articles_map].each do |tagmap|
      Thoth.db[:tags_posts_map] << {
        :id      => tagmap[:id],
        :tag_id  => tagmap[:tag_id],
        :post_id => tagmap[:article_id]
      }
    end
  end

end
