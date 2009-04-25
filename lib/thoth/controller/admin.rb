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

module Thoth
  class AdminController < Controller
    map '/admin'

    def index
      if auth_key_valid?
        @title       = 'Welcome to Thoth'
        @public_root = PUBLIC_DIR
        @view_root   = VIEW_DIR
      else
        @title = 'Login'
      end
    end

    # Authenticates an admin login by checking the _username_ and _password_
    # request parameters against the +ADMIN_USER+ and +ADMIN_PASS+ values in the
    # Thoth config file.
    #
    # On a successful login, an auth cookie named <em>thoth_auth</em> will be
    # set and the user will be redirected to the referring URL. On an
    # unsuccessful login attempt, a flash message named <em>login_error</em>
    # will be set and the user will be redirected to the referring URL without
    # an auth cookie.
    def login
      username, password = request[:username, :password]

      if username == Config.admin['user'] && password == Config.admin['pass']
        # Set an auth cookie that expires in two weeks.
        response.set_cookie('thoth_auth', :expires => Time.now + 1209600,
            :path => MainController.r().to_s, :value => auth_key)

        redirect_referrer
      end

      flash[:error] = 'Invalid username or password.'
      redirect_referrer
    end

    # Deletes the <em>thoth_auth</em> cookie and redirects to the home page.
    def logout
      response.delete_cookie('thoth_auth', :path => MainController.r().to_s)
      redirect(MainController.r())
    end

  end
end
