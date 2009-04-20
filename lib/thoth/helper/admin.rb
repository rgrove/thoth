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

module Ramaze; module Helper

  # The Admin helper provides methods for checking for or requiring
  # authorization from within other actions and views.
  module Admin

    # Include cookie helper.
    def self.included(klass)
      klass.send(:helper, :cookie)
    end

    # Generates and returns an auth key suitable for storage in a client-side
    # auth cookie. The key is an SHA256 hash of the following elements:
    #
    #   - Thoth HOME_DIR path
    #   - user's IP address
    #   - AUTH_SEED from Thoth config
    #   - ADMIN_USER from Thoth config
    #   - ADMIN_PASS from Thoth config
    def auth_key
      Digest::SHA256.hexdigest(Thoth::HOME_DIR + request.ip +
          Thoth::Config.admin.seed + Thoth::Config.admin.user +
          Thoth::Config.admin.pass)
    end

    # Validates the auth cookie and returns +true+ if the user is authenticated,
    # +false+ otherwise.
    def auth_key_valid?
      cookie(:thoth_auth) == auth_key
    end

    # Returns a String that can be included in a hidden form field and used on
    # submission to verify that the form was not submitted by an unauthorized
    # third party.
    def form_token
      Ramaze::Current.session.sid
    end

    # Checks the form token specified by _name_ and returns +true+ if it's
    # valid, +false+ otherwise.
    def form_token_valid?(name = 'token')
      request[name] == form_token
    end

    # Checks the auth cookie and redirects to the login page if the user is not
    # authenticated.
    def require_auth
      redirect(Thoth::AdminController.r()) unless auth_key_valid?
    end
  end

end; end
