# Rackup file for Thoth.

require 'rubygems'
require 'thoth'

module Thoth
  if ENV['RACK_ENV'] == 'development' || ENV['RAILS_ENV'] == 'development'
    trait(:mode => :devel)
  end

  Config.load(trait[:config_file])

  init_thoth
end

Ramaze.start(:file => __FILE__, :started => true)
run Ramaze
