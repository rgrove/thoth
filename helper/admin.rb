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

module Ramaze
  
  # The AdminHelper module provides genric +login+ and +logout+ actions for
  # handling Riposte administrator logins and logouts, along with methods for
  # checking for or requiring authorization from within other actions and views.
  module AdminHelper
    # Include flash and redirect helpers.
    def self.included(klass)
      klass.send(:helper, :flash, :redirect)
    end
    
    # Authenticates an admin login by checking the +username+ and +password+
    # request parameters against the ADMIN_USER and ADMIN_PASS values in the
    # Riposte config file.
    #
    # On a successful login, an auth cookie named +riposte_auth+ will be set and
    # the user will be redirected to the referring URL. On an unsuccessful login
    # attempt, a flash message named +login_error+ will be set and the user will
    # be redirected to the referring URL without an auth cookie.
    def login
      username, password = request[:username, :password]
      
      if username === Riposte::Config::ADMIN_USER &&
          password === Riposte::Config::ADMIN_PASS
        # Set an auth cookie that expires in two weeks.
        response.set_cookie('riposte_auth', :expires => Time.now + 1209600,
            :path => R(MainController), :value => auth_key)
        
        redirect_referrer
      end

      flash[:login_error] = 'Invalid username or password.'
      redirect_referrer
    end
    
    # Deletes the +riposte_auth+ cookie and redirects to the home page.
    def logout
      response.delete_cookie('riposte_auth', :path => R(MainController))
      redirect(Ra(MainController))
    end

    private
    
    # Generates and returns an auth key suitable for storage in a client-side
    # auth cookie. The key is an SHA256 hash of the following elements:
    #
    #   - absolute path of the AdminHelper source file (this file)
    #   - user's IP address
    #   - AUTH_SEED from Riposte config
    #   - ADMIN_USER from Riposte config
    #   - ADMIN_PASS from Riposte config
    def auth_key
      Digest::SHA256.hexdigest(File.expand_path(__FILE__) + request.ip +
          Riposte::Config::AUTH_SEED + Riposte::Config::ADMIN_USER + 
          Riposte::Config::ADMIN_PASS)
    end
    
    # Checks the auth cookie and returns +true+ if the user is authenticated,
    # +false+ otherwise.
    def check_auth
      request.cookies['riposte_auth'] && 
          request.cookies['riposte_auth'] == auth_key
    end
    
    # Checks the auth cookie and redirects to the login page if the user is not
    # authenticated.
    def require_auth
      redirect(Ra(AdminController)) unless check_auth
    end
  end
  
end
