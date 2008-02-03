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

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'

require 'riposte/version'

spec = Gem::Specification.new do |s|
  s.name              = 'riposte'
  s.version           = Riposte::APP_VERSION
  s.author            = Riposte::APP_AUTHOR
  s.email             = Riposte::APP_EMAIL
  s.homepage          = Riposte::APP_URL
  s.platform          = Gem::Platform::RUBY
  s.summary           = 'Meta-gem to install dependencies for the Riposte blog engine.'
  s.rubyforge_project = 'riposte'
  
  s.files = FileList['lib/**/*'].to_a + ['LICENSE', 'README']
  
  s.required_ruby_version = '>=1.8.6'

  s.add_dependency('builder',      '>=2.1.2')
  s.add_dependency('hpricot',      '>=0.6')
  s.add_dependency('json_pure',    '>=1.1.2')
  s.add_dependency('mongrel',      '>=1.0.1')
  s.add_dependency('ramaze',       '>=0.3.5')
  s.add_dependency('sequel',       '>=1.0')
  s.add_dependency('sqlite3-ruby', '>=1.2.1')
  s.add_dependency('swiftiply',    '>=0.6.1.1')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "create bzip2 and tarball"
task :distribute => :gem do
  sh "rm -rf pkg/riposte-#{Riposte::APP_VERSION}"
  sh "mkdir -p pkg/riposte-#{Riposte::APP_VERSION}/db"
  sh "cp -r {controller,helper,model,public,view,LICENSE,README,riposte.conf.sample,riposte-server.rb} pkg/riposte-#{Riposte::APP_VERSION}"
  sh "find pkg -type f -name '._*' -delete" 
  sh "find pkg -type f -name '.DS_Store' -delete" 
  sh "find pkg -type d -name .svn -delete" 
  
  Dir.chdir('pkg') do |pwd|
    sh "tar -zcvf riposte-#{Riposte::APP_VERSION}.tar.gz riposte-#{Riposte::APP_VERSION}"
    sh "tar -jcvf riposte-#{Riposte::APP_VERSION}.tar.bz2 riposte-#{Riposte::APP_VERSION}"
  end
  
  sh "rm -rf pkg/riposte-#{Riposte::APP_VERSION}"
end
