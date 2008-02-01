class AdminController < Ramaze::Controller
  engine :Erubis

  helper :admin
  helper :error
  helper :partial

  layout '/layout/main'
  
  def index
    # TODO: Some kind of dashboard display or something?
    error_404
  end
  
end
