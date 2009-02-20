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

require 'thoth'
require 'thoth/plugin/thoth_twitter'

t = Thoth::Plugin::Twitter

describe 'Thoth::Plugin::Twitter' do
  should 'convert URLs to links' do
    t.parse_tweet('i like http://bacon.com/ because it is https://awesome.net/').
        should.equal('i like <a href="http://bacon.com/">http://bacon.com/</a> because it is <a href="https://awesome.net/">https://awesome.net/</a>')
  end

  should 'convert @usernames to links' do
    t.parse_tweet('@yaypie Thoth is awesome').
        should.equal('@<a href="http://twitter.com/yaypie">yaypie</a> Thoth is awesome')

    t.parse_tweet('RT @thothuser: @yaypie Thoth is awesome').
        should.equal('RT @<a href="http://twitter.com/thothuser">thothuser</a>: @<a href="http://twitter.com/yaypie">yaypie</a> Thoth is awesome')
  end

  should 'convert #hashtags to links' do
    t.parse_tweet('Thoth is awesome #thoth').
        should.equal('Thoth is awesome <a href="http://search.twitter.com/search?q=%23thoth">#thoth</a>')

    t.parse_tweet('Thoth is awesome #thoth #awesome').
        should.equal('Thoth is awesome <a href="http://search.twitter.com/search?q=%23thoth">#thoth</a> <a href="http://search.twitter.com/search?q=%23awesome">#awesome</a>')
  end
end

# TODO: Test the recent_tweets method. Gotta implement an easy Ramaze skeleton
# runner first, though, since Ramaze's own spec helper is poop.
