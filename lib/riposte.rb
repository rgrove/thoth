#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

# Append this file's directory to the include path if it's not there already.
$:.unshift(File.dirname(File.expand_path(__FILE__)))
$:.uniq!

require 'fileutils'

require 'rubygems'
require 'builder'
require 'ramaze'
require 'redcloth'
require 'sequel'
require 'time'
require 'configuration'

# The main Riposte namespace.
module Riposte
  HOME_DIR   = ENV['RIPOSTE_HOME'] || File.expand_path('.') unless const_defined?(:HOME_DIR)
  LIB_DIR    = File.dirname(File.expand_path(__FILE__))/:riposte
  PUBLIC_DIR = LIB_DIR/:public unless const_defined?(:PUBLIC_DIR)
  VIEW_DIR   = LIB_DIR/:view unless const_defined?(:VIEW_DIR)
end

Ramaze::APPDIR.replace(Riposte::LIB_DIR)

require 'riposte/config'
require 'riposte/version'
require 'riposte/plugin'
require 'riposte/monkeypatch/dispatcher/file'

module Riposte
  # Path to the config file.
  trait[:config_file] ||= ENV['RIPOSTE_CONF'] || HOME_DIR/'riposte.conf'
  
  # Daemon command to execute (:start, :stop, :restart) or nil.
  trait[:daemon] ||= nil
  
  # IP address this Riposte instance should attach to.
  trait[:ip] ||= nil
  
  # What mode we're running in (either :devel or :production).
  trait[:mode] ||= :production

  # Port number this Riposte instance should attach to.
  trait[:port] ||= nil
  
  # Path to the daemon process id file.
  trait[:pidfile] ||= HOME_DIR/"riposte_#{trait[:ip]}_#{trait[:port]}.pid"
  
  # Filename to which all SQL commands should be logged, or nil to disable
  # SQL logging.
  trait[:sql_log] ||= nil

  class << self
    attr_reader :db

    # Opens a Sequel database connection to the Riposte database.
    def open_db
      @db = Sequel.open(Config.db)

      if trait[:sql_log]
        require 'logger'
        @db.logger = Logger.new(trait[:sql_log])
      end
    end
    
    # Restarts the running Riposte daemon (if any).
    def restart
      stop
      start
    end

    # Runs Riposte.
    def run
      open_db

      acquire LIB_DIR/:helper/'*'
      acquire LIB_DIR/:controller/'*'
      acquire LIB_DIR/:model/'*'
      
      error = Ramaze::Dispatcher::Error
      error::HANDLE_ERROR[Ramaze::Error::NoAction]     = 
      error::HANDLE_ERROR[Ramaze::Error::NoController] = [404, 'error_404']

      Ramaze::Global.actionless_templates = false
      Ramaze::Global.public_root          = PUBLIC_DIR
      Ramaze::Global.template_root        = VIEW_DIR

      Ramaze::Route[/\/comments\/?/] = '/comment'

      case trait[:mode]
      when :devel
        Ramaze::Global.benchmarking = true

      when :production
        Ramaze::Global.sourcereload = false
      
        if Config.server.error_log.empty?
          Ramaze::Inform.loggers = []
        else
          Ramaze::Inform.loggers = [
            Ramaze::Informer.new(Config.server.error_log, [:error])
          ]
        end

        error::HANDLE_ERROR[ArgumentError] = [404, 'error_404']
        error::HANDLE_ERROR[Exception]     = [500, 'error_500']
    
      else
        raise "Invalid mode: #{trait[:mode]}"
      end
      
      Config.plugins.each {|plugin| Plugin.load(plugin) }
      
      Ramaze.startup :adapter => :evented_mongrel,
          :force  => true,
          :host   => trait[:ip],
          :port   => trait[:port]
    end

    # Starts Riposte as a daemon.
    def start
      # Check the pid file to see if Riposte is already running.
      if File.file?(trait[:pidfile])
        pid = File.read(trait[:pidfile], 20).strip
        abort("riposte already running? (pid=#{pid})")
      end
  
      puts "Starting riposte."
  
      # Fork off and die.
      fork do
        Process.setsid
        exit if fork
    
        # Write PID file.
        File.open(trait[:pidfile], 'w') {|file| file << Process.pid }
    
        # Set working directory.
        Dir.chdir(HOME_DIR)
    
        # Reset umask.
        File.umask(0000)
    
        # Disconnect file descriptors.
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen(STDOUT)
    
        # Run Riposte.
        run
      end
    end

    # Stops the running Riposte daemon (if any).
    def stop
      unless File.file?(trait[:pidfile])
        abort("riposte not running? (check #{trait[:pidfile]}).")
      end
  
      puts "Stopping riposte."
  
      pid = File.read(trait[:pidfile], 20).strip
      FileUtils.rm(trait[:pidfile])
  
      pid && Process.kill('TERM', pid.to_i)
    end
  end

end
