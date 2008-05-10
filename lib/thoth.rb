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
require 'cssmin'
require 'jsmin'
require 'ramaze'
require 'redcloth'
require 'sequel'
require 'time'
require 'configuration'

# The main Thoth namespace.
module Thoth
  HOME_DIR   = ENV['THOTH_HOME'] || File.expand_path('.') unless const_defined?(:HOME_DIR)
  LIB_DIR    = File.dirname(File.expand_path(__FILE__))/:thoth
  PUBLIC_DIR = LIB_DIR/:public unless const_defined?(:PUBLIC_DIR)
  VIEW_DIR   = LIB_DIR/:view unless const_defined?(:VIEW_DIR)
end

require 'thoth/errors'
require 'thoth/config'
require 'thoth/version'
require 'thoth/plugin'
require 'thoth/monkeypatch/dispatcher/file'

module Thoth
  R = Ramaze

  # Path to the config file.
  trait[:config_file] ||= ENV['THOTH_CONF'] || HOME_DIR/'thoth.conf'

  # Daemon command to execute (:start, :stop, :restart) or nil.
  trait[:daemon] ||= nil

  # IP address this Thoth instance should attach to.
  trait[:ip] ||= nil

  # What mode we're running in (either :devel or :production).
  trait[:mode] ||= :production

  # Port number this Thoth instance should attach to.
  trait[:port] ||= nil

  # Path to the daemon process id file.
  trait[:pidfile] ||= HOME_DIR/"thoth_#{trait[:ip]}_#{trait[:port]}.pid"

  # Filename to which all SQL commands should be logged, or nil to disable
  # SQL logging.
  trait[:sql_log] ||= nil

  class << self
    attr_reader :db

    # Creates a new Thoth home directory with a sample config file at the
    # specified path.
    def create(path)
      path = File.expand_path(path)

      if File.exist?(path)
        raise "specified path already exists: #{path}"
      end

      FileUtils.mkdir_p(path/:media)
      FileUtils.mkdir(path/:plugin)
      FileUtils.mkdir(path/:public)
      FileUtils.mkdir(path/:view)
      FileUtils.cp(LIB_DIR/'..'/:proto/'thoth.conf.sample', path/'thoth.conf')
      File.chmod(0640, path/'thoth.conf')
    end

    # Initializes Ramaze (but doesn't actually start the server).
    def init_ramaze
      R::Global.setup(
        :root                 => LIB_DIR,
        :public_root          => PUBLIC_DIR,
        :view_root            => VIEW_DIR,
        :actionless_templates => false,
        :compile              => Config.server.compile_views
      )

      # Display a 404 error for requests that don't map to a controller or
      # action.
      R::Dispatcher::Error::HANDLE_ERROR.update({
        R::Error::NoAction     => [404, 'error_404'],
        R::Error::NoController => [404, 'error_404']
      })

      case trait[:mode]
      when :devel
        R::Global.benchmarking = true

      when :production
        R::Global.sourcereload = false

        # Log all errors to the error log file if one is configured.
        R::Log.loggers = Config.server.error_log.empty? ? [] :
            [R::Informer.new(Config.server.error_log, [:error])]

        # Don't expose argument errors or exceptions in production mode.
        R::Dispatcher::Error::HANDLE_ERROR.update({
          ArgumentError => [404, 'error_404'],
          Exception     => [500, 'error_500']
        })

      else
        raise "Invalid mode: #{trait[:mode]}"
      end
    end

    # Opens a connection to the Thoth database and loads helpers, controllers,
    # models and plugins.
    def init_thoth
      trait[:ip]   ||= Config.server.address
      trait[:port] ||= Config.server.port

      R::Log.info "Thoth home: #{HOME_DIR}"
      R::Log.info "Thoth lib : #{LIB_DIR}"

      open_db

      unless @db.table_exists?(:posts)
        raise SchemaError, "Database schema is missing or out of date. " <<
            "Please run `thoth --migrate`."
      end

      acquire LIB_DIR/:helper/'*'
      require LIB_DIR/:controller/:post # must be loaded first
      acquire LIB_DIR/:controller/'*'
      acquire LIB_DIR/:model/'*'

      # Use Erubis as the template engine for all controllers.
      R::Global.mapping.values.each do |controller|
        controller.trait[:engine] = R::Template::Erubis
      end

      # If minification is enabled, intercept CSS/JS requests and route them to
      # the MinifyController.
      if Config.server.enable_minify
        R::Rewrite[/^\/(css|js)\/(.+)$/] = '/minify/%s/%s'
      end

      Config.plugins.each {|plugin| Plugin.load(plugin) }
    end

    # Opens a Sequel database connection to the Thoth database.
    def open_db
      if Config.db =~ /^sqlite:\/{3}(.+)$/
        dir = File.dirname($1)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
      end

      @db = Sequel.open(Config.db)

      if trait[:sql_log]
        require 'logger'
        @db.logger = Logger.new(trait[:sql_log])
      end
    end

    # Restarts the running Thoth daemon (if any).
    def restart
      stop
      sleep(1)
      start
    end

    # Runs Thoth.
    def run
      init_ramaze
      init_thoth

      R.startup(
        :adapter => :thin,
        :force   => true,
        :host    => trait[:ip],
        :port    => trait[:port]
      )
    end

    # Starts Thoth as a daemon.
    def start
      if File.file?(trait[:pidfile])
        pid = File.read(trait[:pidfile], 20).strip
        abort("thoth already running? (pid=#{pid})")
      end

      puts "Starting thoth."

      fork do
        Process.setsid
        exit if fork

        File.open(trait[:pidfile], 'w') {|file| file << Process.pid }
        at_exit {FileUtils.rm(trait[:pidfile]) if File.exist?(trait[:pidfile])}

        Dir.chdir(HOME_DIR)
        File.umask(0000)

        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen(STDOUT)

        run
      end
    end

    # Stops the running Thoth daemon (if any).
    def stop
      unless File.file?(trait[:pidfile])
        abort("thoth not running? (check #{trait[:pidfile]}).")
      end

      puts "Stopping thoth."

      pid = File.read(trait[:pidfile], 20).strip
      FileUtils.rm(trait[:pidfile]) if File.exist?(trait[:pidfile])
      pid && Process.kill('TERM', pid.to_i)
    end
  end
end
