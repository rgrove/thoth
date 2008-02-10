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

# Append the Riposte /lib directory to the include path if it's not there
# already.
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
$:.uniq!

require 'find'

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'riposte/version'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec for Riposte
riposte_gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'riposte'
  s.version  = Riposte::APP_VERSION
  s.author   = Riposte::APP_AUTHOR
  s.email    = Riposte::APP_EMAIL
  s.homepage = Riposte::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary  = 'Meta-gem to install dependencies and core libs for the ' +
               'Riposte blog engine.'

  s.files        = FileList['lib/**/*'].to_a + ['LICENSE']
  s.require_path = 'lib'
  s.has_rdoc     = true

  s.required_ruby_version = '>=1.8.6'

  s.add_dependency('builder',      '>=2.1.2')
  s.add_dependency('erubis',       '>=2.5.0')
  s.add_dependency('hpricot',      '>=0.6')
  s.add_dependency('json_pure',    '>=1.1.2')
  s.add_dependency('mongrel',      '>=1.0.1')
  s.add_dependency('ramaze',       '>=0.3.6')
  s.add_dependency('sequel',       '>=1.0')
  s.add_dependency('sqlite3-ruby', '>=1.2.1')
  s.add_dependency('swiftiply',    '>=0.6.1.1')
end

plugins = []

# del.icio.us plugin
plugins << Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'riposte_delicious'
  s.version  = Riposte::APP_VERSION
  s.author   = Riposte::APP_AUTHOR
  s.email    = Riposte::APP_EMAIL
  s.homepage = Riposte::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary  = 'del.icio.us plugin for the Riposte blog engine.'

  s.files        = ['plugin/riposte_delicious.rb']
  s.require_path = 'plugin'
  s.has_rdoc     = true
  
  s.add_dependency('json_pure', '>=0.0.1')
  s.add_dependency('riposte',   ">=#{Riposte::APP_VERSION}")
end

# Flickr plugin
plugins << Gem::Specification.new do |s|
  s.rubyforge_project = 'riposte'

  s.name     = 'riposte_flickr'
  s.version  = Riposte::APP_VERSION
  s.author   = Riposte::APP_AUTHOR
  s.email    = Riposte::APP_EMAIL
  s.homepage = Riposte::APP_URL
  s.platform = Gem::Platform::RUBY
  s.summary  = 'Flickr plugin for the Riposte blog engine.'

  s.files        = ['plugin/riposte_flickr.rb']
  s.require_path = 'plugin'
  s.has_rdoc     = true
  
  s.add_dependency('net-flickr', '>=0.0.1')
  s.add_dependency('riposte',    ">=#{Riposte::APP_VERSION}")
end

Rake::GemPackageTask.new(riposte_gemspec) do |p|
  p.need_tar_gz = true
end

Rake::RDocTask.new do |rd|
  rd.main     = 'Riposte'
  rd.title    = 'Riposte'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('lib/**/*.rb')
end

Rake::RDocTask.new(:rdoc_delicious) do |rd|
  rd.main     = 'Riposte::Plugin::Delicious'
  rd.title    = 'Riposte::Plugin::Delicious'
  rd.rdoc_dir = 'doc/delicious'
  
  rd.rdoc_files.include('plugin/riposte_delicious.rb')
end

Rake::RDocTask.new(:rdoc_flickr) do |rd|
  rd.main     = 'Riposte::Plugin::Flickr'
  rd.title    = 'Riposte::Plugin::Delicious'
  rd.rdoc_dir = 'doc/flickr'
  
  rd.rdoc_files.include('plugin/riposte_flickr.rb')
end

desc "create tarball"
task :package => :gem do
  pkgname = "riposte-#{Riposte::APP_VERSION}"
  pkgdir  = "pkg/#{pkgname}"
  
  sh "rm -rf #{pkgdir}"
  sh "mkdir -p #{pkgdir}/db"
  sh "cp -r {controller,helper,model,public,scripts,view,LICENSE,riposte.conf.sample,riposte-server.rb} #{pkgdir}"
  
  Find.find(pkgdir) do |path|
    name = File.basename(path)
    
    if File.directory?(path)
      if name == '.svn' 
        FileUtils.rm_rf(path)    
      end      
    else
      if name == '.DS_Store'
        FileUtils.rm_f(path)
      end
    end
  end
  
  Dir.chdir('pkg') do |pwd|
    sh "tar -zcvf #{pkgname}.tar.gz #{pkgname}"
  end
  
  sh "rm -rf #{pkgdir}"
end

desc "install Riposte"
task :install => :gem do
  sh "sudo gem install pkg/riposte-#{Riposte::APP_VERSION}.gem"
end

desc "create plugin gems"
task :plugins do
  plugins.each do |spec|
    gem_file = "#{spec.name}-#{spec.version}.gem"
    
    Gem::Builder.new(spec).build
    verbose(true) {
      mv gem_file, "pkg/#{gem_file}"
    }

  end
end
