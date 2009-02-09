#--
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
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

gem 'ramaze', '=2009.01'

require 'builder'
require 'cssmin'
require 'jsmin'
require 'json'
require 'ramaze'
require 'redcloth'
require 'sanitize'
require 'sequel'
require 'time'
require 'configuration'

# The main Thoth namespace.
module Thoth
  HOME_DIR   = ENV['THOTH_HOME'] || File.expand_path('.') unless const_defined?(:HOME_DIR)
  LIB_DIR    = File.join(File.dirname(File.expand_path(__FILE__)), 'thoth')
  PUBLIC_DIR = File.join(LIB_DIR, 'public') unless const_defined?(:PUBLIC_DIR)
  VIEW_DIR   = File.join(LIB_DIR, 'view') unless const_defined?(:VIEW_DIR)
end

require 'thoth/errors'
require 'thoth/config'
require 'thoth/version'
require 'thoth/plugin'
require 'thoth/monkeypatch/ramaze/controller'
require 'thoth/monkeypatch/ramaze/dispatcher/file'

module Thoth
  # Ramaze adapter to use.
  trait[:adapter] ||= nil

  # Path to the config file.
  trait[:config_file] ||= ENV['THOTH_CONF'] || File.join(HOME_DIR, 'thoth.conf')

  # Daemon command to execute (:start, :stop, :restart) or nil.
  trait[:daemon] ||= nil

  # IP address this Thoth instance should attach to.
  trait[:ip] ||= nil

  # Whether or not to start Thoth within an IRB session.
  trait[:irb] ||= false

  # What mode we're running in (either :devel or :production).
  trait[:mode] ||= :production

  # Port number this Thoth instance should attach to.
  trait[:port] ||= nil

  # Path to the daemon process id file.
  trait[:pidfile] ||= File.join(HOME_DIR, "thoth_#{trait[:ip]}_#{trait[:port]}.pid")

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

      FileUtils.mkdir_p(File.join(path, 'log'))
      FileUtils.mkdir(File.join(path, 'media'))
      FileUtils.mkdir(File.join(path, 'plugin'))
      FileUtils.mkdir(File.join(path, 'public'))
      FileUtils.mkdir(File.join(path, 'view'))
      FileUtils.mkdir(File.join(path, 'tmp'))

      FileUtils.cp(File.join(LIB_DIR, '..', 'proto', 'config.ru'), File.join(path, 'config.ru'))
      FileUtils.cp(File.join(LIB_DIR, '..', 'proto', 'thoth.conf.sample'), File.join(path, 'thoth.conf'))

      File.chmod(0750, File.join(path, 'log'))
      File.chmod(0640, File.join(path, 'thoth.conf'))
    end

    # Initializes Ramaze (but doesn't actually start the server).
    def init_ramaze
      Ramaze::Global.setup(
        :root                 => LIB_DIR,
        :public_root          => PUBLIC_DIR,
        :view_root            => VIEW_DIR,
        :actionless_templates => false,
        :compile              => Config.server.compile_views
      )

      # Display a 404 error for requests that don't map to a controller or
      # action.
      Ramaze::Dispatcher::Error::HANDLE_ERROR.update({
        Ramaze::Error::NoAction     => [404, 'error_404'],
        Ramaze::Error::NoController => [404, 'error_404']
      })

      case trait[:mode]
      when :devel
        Ramaze::Global.benchmarking = true

      when :production
        Ramaze::Global.sourcereload = false

        # Log all errors to the error log file if one is configured.
        if Config.server.error_log.empty?
          Ramaze::Log.loggers = []
        else
          log_dir = File.dirname(Config.server.error_log)

          unless File.directory?(log_dir)
            FileUtils.mkdir_p(log_dir)
            File.chmod(0750, log_dir)
          end

          Ramaze::Log.loggers = [
            Ramaze::Logger::Informer.new(Config.server.error_log,
                [:error])
          ]
        end

        # Don't expose argument errors or exceptions in production mode.
        Ramaze::Dispatcher::Error::HANDLE_ERROR.update({
          ArgumentError => [404, 'error_404'],
          Exception     => [500, 'error_500']
        })

      else
        raise "Invalid mode: #{trait[:mode]}"
      end

      Ramaze::Global.console = trait[:irb]
    end

    # Opens a connection to the Thoth database and loads helpers, controllers,
    # models and plugins.
    def init_thoth
      trait[:ip]   ||= Config.server.address
      trait[:port] ||= Config.server.port

      Ramaze::Log.info "Thoth home: #{HOME_DIR}"
      Ramaze::Log.info "Thoth lib : #{LIB_DIR}"

      open_db

      # Ensure that the database schema is up to date.
      unless Sequel::Migrator.get_current_migration_version(@db) ==
          Sequel::Migrator.latest_migration_version(File.join(LIB_DIR, 'migrate'))

        if trait[:mode] == :production
          raise SchemaError, "Database schema is missing or out of date. " <<
              "Please run `thoth --migrate`."
        else
          raise SchemaError, "Database schema is missing or out of date. " <<
              "Please run `thoth --devel --migrate`."
        end
      end

      Ramaze::acquire(File.join(LIB_DIR, 'helper', '*'))
      require File.join(LIB_DIR, 'controller', 'post') # must be loaded first
      Ramaze::acquire(File.join(LIB_DIR, 'controller', '*'))
      Ramaze::acquire(File.join(LIB_DIR, 'controller', 'api', '*'))
      Ramaze::acquire(File.join(LIB_DIR, 'model', '*'))

      # Use Erubis as the template engine for all controllers.
      Ramaze::Global.mapping.values.each do |controller|
        controller.trait[:engine] = Ramaze::Template::Erubis
      end

      # If minification is enabled, intercept CSS/JS requests and route them to
      # the MinifyController.
      if Config.server.enable_minify
        Ramaze::Rewrite[/^\/(css|js)\/(.+)$/] = '/minify/%s/%s'
      end

      Config.plugins.each {|plugin| Plugin.load(plugin)}
    end

    # Opens a Sequel database connection to the Thoth database.
    def open_db
      if Config.db =~ /^sqlite:\/{3}(.+)$/
        dir = File.dirname($1)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
      end

      Sequel.datetime_class = Time

      @db = Sequel.open(Config.db)

      unless @db.test_connection
        Ramaze::Log.error('Unable to connect to database.')
        abort
      end

      if trait[:sql_log]
        require 'logger'
        @db.logger = Logger.new(trait[:sql_log])
      end

    rescue => e
      Ramaze::Log.error("Unable to connect to database: #{e}")
      abort
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

      Ramaze.startup(
        :force   => true,
        :adapter => trait[:adapter],
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

        File.open(trait[:pidfile], 'w') {|file| file << Process.pid}
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
