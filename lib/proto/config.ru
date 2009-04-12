# Rackup file for Thoth.

require 'rubygems'
require 'thoth'

module Thoth
  if ENV['RACK_ENV'] == 'development' || ENV['RAILS_ENV'] == 'development'
    trait(:mode => :devel)
  end

  Config.load(trait[:config_file])

  init_ramaze
  init_thoth
end

Ramaze.trait[:essentials].delete Ramaze::Adapter
Ramaze.start!

run Ramaze::Adapter::Base
