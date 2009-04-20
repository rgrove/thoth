module Thoth
  class Controller < Ramaze::Controller
    helper :error
    engine :Erubis
    layout :default
    map_layouts '/'

    trait :app => :thoth

    # Displays a custom 404 error when a nonexistent action is requested.
    def self.action_missing(path)
      return if path == '/error_404'
      try_resolve('/error_404')
    end
  end

  Ramaze::acquire(File.join(LIB_DIR, 'controller', '*'))
  Ramaze::acquire(File.join(LIB_DIR, 'controller', 'api', '*'))
end
