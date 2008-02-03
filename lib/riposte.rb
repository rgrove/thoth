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
$:.unshift(File.dirname(__FILE__))
$:.uniq!

require 'rubygems'
require 'builder'
require 'ramaze'
require 'sequel'
require 'time'

require 'riposte/config'
require 'riposte/linkhelper'
require 'riposte/version'

module Riposte
  
  class << self
    attr_reader :db

    # Restart the running Riposte daemon (if any).
    def restart
      stop
      start
    end

    # Run Riposte.
    def run
      Config.load_config(CONFIG_FILE)

      # Set up the database connection.
      @db = Sequel.open(DEVEL_MODE ? Config::DB_TEST : Config::DB_PRODUCTION)

      if LOG_SQL
        require 'logger'
        @db.logger = Logger.new(LOG_SQL)
      end

      # Load controllers and models.
      acquire "#{Ramaze::APPDIR}/controller/*"
      acquire "#{Ramaze::APPDIR}/model/*"

      # Set up error handlers.
      Ramaze::Dispatcher::Error::HANDLE_ERROR[Ramaze::Error::NoAction] = 
      Ramaze::Dispatcher::Error::HANDLE_ERROR[Ramaze::Error::NoController] = [404, 'error_404']

      if DEVEL_MODE
        Ramaze::Global.benchmarking = true
      else
        Ramaze::Global.compile      = true
        Ramaze::Global.sourcereload = false
        Ramaze::Inform.ignored_tags = [:debug]
        Ramaze::Inform.loggers      = []

        Ramaze::Dispatcher::Error::HANDLE_ERROR[ArgumentError] = [404, 'error_404']
        Ramaze::Dispatcher::Error::HANDLE_ERROR[Exception]     = [500, 'error_500']
      end
      
      Ramaze.start :adapter => :evented_mongrel, :host => IP, :port => PORT,
          :force => true
    end

    # Start Riposte as a daemon.
    def start
      # Check the pid file to see if Riposte is already running.
      if File.file?(PID_FILE)
        pid = File.read(PID_FILE, 20).strip
        abort("riposte already running? (pid=#{pid})")
      end
  
      puts "Starting riposte."
  
      # Fork off and die.
      fork do
        Process.setsid
        exit if fork
    
        # Write PID file.
        File.open(PID_FILE, 'w') {|file| file << Process.pid }
    
        # Set working directory.
        Dir.chdir(Ramaze::APPDIR)
    
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

    # Stop the running Riposte daemon (if any).
    def stop
      unless File.file?(PID_FILE)
        abort("riposte not running? (check #{PID_FILE}).")
      end
  
      puts "Stopping riposte."
  
      pid = File.read(PID_FILE, 20).strip
      FileUtils.rm(PID_FILE)
  
      pid && Process.kill('TERM', pid.to_i)
    end
  end

end
