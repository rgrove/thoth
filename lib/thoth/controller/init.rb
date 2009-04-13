module Thoth
  class Controller < Ramaze::Controller
    engine :Erubis
    layout :default
    trait  :app => :thoth

    private

    # This is here temporarily until manveru adds it back to Innate
    def render_template(file_name, variables = {})
      render_custom(action.name, variables) do |action|
        action.layout = nil
        action.method = nil
        action.view   = File.join(LIB_DIR, 'view', file_name + '.rhtml') # FIXME: this is a hack and doesn't work for views in subdirectories
      end
    end
  end

  # require File.join(LIB_DIR, 'controller', 'post')
  
  Ramaze::acquire(File.join(LIB_DIR, 'controller', '*'))
  Ramaze::acquire(File.join(LIB_DIR, 'controller', 'api', '*'))
end

