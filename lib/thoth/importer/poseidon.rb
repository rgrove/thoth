#
# Poseidon 0.3 -> Thoth importer.
#

class PoseidonImporter < Thoth::Importer
  
  before_import do
    unless uri = ARGV.shift
      puts "Please enter a connection string for the Poseidon database you want to import."
      puts "Example: mysql://user:pass@localhost/dbname"
      print "> "
      
      uri = STDIN.gets.strip
      puts
    end
    
    begin
      @poseidon = Sequel.open(uri)
    rescue => e
      abort("Error: unable to connect to database: #{e}")
    end
  end

  import_comments do
    @poseidon[:comments].all do |row|
      user = @poseidon[:users].filter(:id => row[:userid]).first
    
      Comment.create do |comment|
        comment.id         = row[:id]
        comment.author     = user[:username]
        comment.author_url = ''
        comment.title      = row[:title]
        comment.body       = row[:content]
        comment.created_at = Time.at(row[:posted])
        comment.updated_at = Time.at(row[:posted])
        comment.ip         = row[:ip]
        comment.post_id    = row[:contentid]
      end
    end
  end
  
  import_posts do
    @poseidon[:content].each do |row|
      Post.create do |post|
        post.id         = row[:id]
        post.title      = row[:title]
        post.body       = row[:content]
        post.created_at = Time.at(row[:posted])
        post.updated_at = Time.at(row[:posted])
      end
    end
  end
  
end
