RIPOSTE_VERSION = '0.0.1 alpha'

require 'rubygems'
require 'builder'
require 'ramaze'
require 'sequel'
require 'time'

require 'helper/sanitize'
require 'config'

# Set up the database connection.
if DEVEL_MODE
  DB = Sequel.open(DB_TEST)
  
  Ramaze::Global.benchmarking = true

  if LOG_SQL
    require 'logger'
    DB.logger = Logger.new("#{__DIR__}/db/sql.log")
  end
else
  DB = Sequel.open(DB_PRODUCTION)

  Ramaze::Global.compile      = true
  Ramaze::Global.sourcereload = false
end

# Load all controllers and models.
acquire __DIR__/:controller/'*'
acquire __DIR__/:model/'*'

# Set up error handlers.
Ramaze::Dispatcher::Error::HANDLE_ERROR[Ramaze::Error::NoAction] = 
Ramaze::Dispatcher::Error::HANDLE_ERROR[Ramaze::Error::NoController] = [
  404, 'error_404'
]

unless DEVEL_MODE
  Ramaze::Dispatcher::Error::HANDLE_ERROR[ArgumentError] = [404, 'error_404']
  Ramaze::Dispatcher::Error::HANDLE_ERROR[Exception]     = [500, 'error_500']
end

Ramaze.start :adapter => :mongrel, :port => 7000
