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

# Prepend the Thoth /lib directory to the include path if it's not there
# already.
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
$:.uniq!

require 'find'

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'thoth/version'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec for Thoth
thoth_gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'thoth'
  s.version  = Thoth::APP_VERSION
  s.author   = Thoth::APP_AUTHOR
  s.email    = Thoth::APP_EMAIL
  s.homepage = Thoth::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary  = 'An awesome blog engine based on Ramaze and Sequel.'

  s.files        = FileList['{bin,lib}/**/*', 'LICENSE'].to_a
  s.executables  = ['thoth']
  s.require_path = 'lib'

  s.required_ruby_version = '>= 1.8.6'

  # Runtime dependencies.
  s.add_dependency('ramaze',    '= 2009.04')
  s.add_dependency('builder',   '~> 2.1.2')
  s.add_dependency('cssmin',    '~> 1.0.2')
  s.add_dependency('erubis',    '~> 2.6.2')
  s.add_dependency('json_pure', '~> 1.1.3')
  s.add_dependency('jsmin',     '~> 1.0.1')
  s.add_dependency('RedCloth',  '~> 4.1.9')
  s.add_dependency('sanitize',  '~> 1.0.8')
  s.add_dependency('sequel',    '~> 3.0.0')

  # Development dependencies.
  s.add_development_dependency('bacon', '~> 1.1')
  s.add_development_dependency('rake',  '~> 0.8')

  s.post_install_message = <<POST_INSTALL
================================================================================
Thank you for installing Thoth. If you haven't already, you may need to install
one or more of the following gems:

  mysql        - If you want to use Thoth with a MySQL database
  passenger    - If you want to run Thoth under Apache using Phusion Passenger
  sqlite3-ruby - If you want to use Thoth with a SQLite database
  thin         - If you want to run Thoth using Thin
================================================================================
POST_INSTALL
end

Rake::GemPackageTask.new(thoth_gemspec) do |p|
  p.need_tar_gz = true
end

Rake::RDocTask.new do |rd|
  rd.main     = 'Thoth'
  rd.title    = 'Thoth'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('lib/**/*.rb')
end

task :default => [:test]

task :test do
  sh 'bacon -a'
end

desc "install Thoth"
task :install => :gem do
  sh "gem install pkg/thoth-#{Thoth::APP_VERSION}.gem"
end

desc "remove end-of-line whitespace"
task 'strip-spaces' do
  Dir['lib/**/*.{css,js,rb,rhtml,sample}'].each do |file|
    next if file =~ /^\./

    original = File.readlines(file)
    stripped = original.dup

    original.each_with_index do |line, i|
      if line =~ /\s+\n/
        puts "fixing #{file}:#{i + 1}"
        p line
        stripped[i] = line.rstrip
      end
    end

    unless stripped == original
      File.open(file, 'w') do |f|
        stripped.each {|line| f.puts(line) }
      end
    end
  end
end
