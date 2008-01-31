if RUBY_VERSION >= '1.9.0'
  require 'digest/sha1'
else
  require 'digest/sha2'
end

module Ramaze
  
  module AdminHelper
    # Include flash and redirect helpers.
    def self.included(klass)
      klass.send(:helper, :flash, :redirect)
    end
    
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
    
    def logout
      response.delete_cookie('riposte_auth', :path => R(MainController))
      redirect_referrer
    end

    private
    
    def auth_key
      Digest::SHA256.hexdigest(File.expand_path(__FILE__) + request.ip +
          AUTH_SEED + USERNAME + PASSWORD)
    end
    
    def check_auth
      request.cookies['riposte_auth'] && 
          request.cookies['riposte_auth'] === auth_key
    end
    
    def require_auth
      redirect_referrer unless check_auth
    end
  end
  
end
