module Thoth
  class Controller < Ramaze::Controller
    engine :Erubis
    layout :default
    trait  :app => :thoth

  end

  require File.join(LIB_DIR, 'controller', 'main')
  # require File.join(LIB_DIR, 'controller', 'post')
  # 
  # Ramaze::acquire(File.join(LIB_DIR, 'controller', '*'))
  # Ramaze::acquire(File.join(LIB_DIR, 'controller', 'api', '*'))
end

