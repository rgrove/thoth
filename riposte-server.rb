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

# = riposte-server.rb
#
# Riposte startup script. Starts an Evented Mongrel instance listening for
# connections on the specified IP address and port (or 0.0.0.0:7000 if not
# specified).
#
# == Usage
#
#   ruby riposte-server.rb [--config <file>] [--daemon <start|stop|restart>]
#                          [--devel] [--ip <address>] [--log-sql <file>]
#                          [--port <number>]

require 'optparse'

require 'rubygems'
require 'riposte'

module Riposte
  
  DIR = File.expand_path(File.dirname(__FILE__))

  options = {
    :config  => ENV['RIPOSTE_CONF'] || DIR/'riposte.conf',
    :daemon  => nil,
    :devel   => false,
    :ip      => nil,
    :log_sql => nil,
    :port    => nil
  }
  
  # Parse command-line options.
  optparse = OptionParser.new do |o|
    o.summary_indent = '  '
    o.summary_width  = 24
    o.banner         = 'Usage: ruby riposte-server.rb [options]'
    
    o.separator ''
    o.separator 'Options:'
    
    o.on('-c', '--config [filename]',
        'Use the specified configuration file.') do |filename|
      options[:config] = File.expand_path(filename)
    end
    
    o.on('-d', '--daemon [command]', [:start, :stop, :restart],
        'Issue the specified daemon command (start, stop, or',
        'restart).') do |cmd|
      options[:daemon] = cmd
    end
    
    o.on('--devel',
        'Run Riposte in development mode.') do
      options[:devel] = true
    end
    
    o.on('-i', '--ip [address]',
        'Listen for connections on the specified IP address.') do |address|
      options[:ip] = address
    end
    
    o.on('--log-sql [filename]',
        'Log all SQL queries to the specified file.') do |filename|
      options[:log_sql] = File.expand_path(filename)
    end
    
    o.on('-p', '--port [number]',
        'Listen for connections on the specified port number.') do |port|
      options[:port] = port.to_i
    end
    
    o.on_tail('-h', '--help',
        'Display usage information (this message).') do
      puts o
      exit
    end
    
    o.on_tail('-v', '--version',
        'Display version information.') do
      puts "#{APP_NAME} v#{APP_VERSION} <#{APP_URL}>"
      puts "#{APP_COPYRIGHT}"
      puts
      puts "#{APP_NAME} comes with ABSOLUTELY NO WARRANTY."
      puts
      puts "This program is open source software distributed under the BSD license. For"
      puts "details, see the LICENSE file contained in the source distribution."
      exit
    end
  end
  
  begin 
    optparse.parse!(ARGV)
  rescue => e
    abort("Error: #{e}")
  end
  
  Config.load(options[:config], options[:devel] ? :devel : :production)
  
  CONFIG_FILE = options[:config]
  DEVEL_MODE  = options[:devel]
  IP          = options[:ip] || Config.server.address
  LOG_SQL     = options[:log_sql]
  PORT        = options[:port] || Config.server.port
  PID_FILE    = DIR/"riposte_#{IP}_#{PORT}.pid"

  case options[:daemon]
  when :restart
    restart
  when :start
    start
  when :stop
    stop
  else
    run
  end

end
