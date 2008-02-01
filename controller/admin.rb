class AdminController < Ramaze::Controller
  engine :Erubis

  helper :admin
  helper :error
  helper :flash
  helper :partial

  layout '/layout/main'
  
  def index
    if check_auth
      @title         = 'Welcome to Riposte'
      @template_root = File.join(Ramaze::APPDIR, Ramaze::Global.template_root)
      @public_root   = File.join(Ramaze::APPDIR, Ramaze::Global.public_root)
    else
      @title = 'Login'
    end
  end  
end
