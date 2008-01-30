# Name of your blog.
SITE_NAME = 'wonko.com'

# Description of your blog.
SITE_DESCRIPTION = 'The eclectic musings of a bitter software engineer.'

# Absolute URL of your site.
SITE_URL = 'http://wonko.com/'

# Your name.
AUTHOR_NAME = 'Ryan Grove'

# Your email address.
AUTHOR_EMAIL = 'ryan@wonko.com'

# Date-only timestamp format.
# See http://www.ruby-doc.org/core/classes/Time.html#M000297
TIMESTAMP_DATE = '%A %B %d, %Y'

# Long timestamp format.
# See http://www.ruby-doc.org/core/classes/Time.html#M000297
TIMESTAMP_LONG = '%A %B %d, %Y @ %I:%M %p (%Z)'

# Long timestamp format.
# See http://www.ruby-doc.org/core/classes/Time.html#M000297
TIMESTAMP_SHORT = '%Y-%m-%d %I:%M'

# Whether or not to enable caching.
ENABLE_CACHE = false

# Connection URI for the production database.
DB_PRODUCTION = "sqlite:///#{__DIR__}/db/production.db"

# Connection URI for the test database.
DB_TEST = "sqlite:///#{__DIR__}/db/test.db"

# Whether or not to run in development mode.
DEVEL_MODE = true

# Whether or not to log all SQL queries.
LOG_SQL = false
