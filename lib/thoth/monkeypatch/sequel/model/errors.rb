module Sequel; class Model

  class Errors
    def on_field(att)
      on(att) || []
    end
  end

end; end
