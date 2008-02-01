if RUBY_VERSION >= '1.9.0'
  require 'digest/sha1'
else
  require 'digest/sha2'
end

module Ramaze
  
  # The AdminHelper module provides genric +login+ and +logout+ actions for
  # handling Riposte administrator logins and logouts, along with methods for
  # checking for or requiring authorization from within other actions and views.
  module AdminHelper
    # Include flash and redirect helpers.
    def self.included(klass)
      klass.send(:helper, :error, :flash, :redirect)
    end
    
    # Authenticates an admin login by checking the +username+ and +password+
    # request parameters against the USERNAME and PASSWORD values in config.rb.
    #
    # On a successful login, an auth cookie named +riposte_auth+ will be set and
    # the user will be redirected to the referring URL. On an unsuccessful login
    # attempt, a flash message named +login_error+ will be set and the user will
    # be redirected to the referring URL without an auth cookie.
    def login
      username, password = request[:username, :password]
      
      if username === USERNAME && password === PASSWORD
        # Set an auth cookie that expires in two weeks.
        response.set_cookie('riposte_auth', :expires => Time.now + 1209600,
            :path => R(MainController), :value => auth_key)
        
        redirect_referrer
      end

      flash[:login_error] = 'Invalid username or password.'
      redirect_referrer
    end
    
    # Deletes the +riposte_auth+ cookie and redirects to the referring URL.
    def logout
      response.delete_cookie('riposte_auth', :path => R(MainController))
      redirect_referrer
    end

    private
    
    # Generates and returns an auth key suitable for storage in a client-side
    # auth cookie. The key is an SHA256 hash of the following elements:
    #
    #   - absolute path of the AdminHelper source file (this file)
    #   - user's IP address
    #   - AUTH_SEED from config.rb
    #   - USERNAME from config.rb
    #   - PASSWORD from config.rb
    def auth_key
      Digest::SHA256.hexdigest(File.expand_path(__FILE__) + request.ip +
          AUTH_SEED + USERNAME + PASSWORD)
    end
    
    # Checks the auth cookie and returne +true+ if the user is authenticated,
    # +false+ otherwise.
    def check_auth
      request.cookies['riposte_auth'] && 
          request.cookies['riposte_auth'] === auth_key
    end
    
    # Checks the auth cookie and responds with a 404 error if the user is not
    # authenticated.
    def require_auth
      error_404 unless check_auth
    end
  end
  
end
