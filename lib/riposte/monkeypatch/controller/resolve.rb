module Ramaze
  
  # Monkeypatch to prevent templates other than layout from being rendered as
  # the result of a request unless they have a corresponding controller method. 
  class Controller
    
    class << self
      def resolve_action(path, *parameter)
        path, parameter = path.to_s, parameter.map{|e| e.to_s}
        if alternate_template = trait["#{path}_template"]
          t_controller, t_path = *alternate_template
          template = t_controller.resolve_template(t_path)
        end

        method, params = resolve_method(path, *parameter)

        if method or (parameter.empty? and path == 'layout')
          template ||= resolve_template(path)
        end

        Action.create :path       => path,
                      :method     => method,
                      :params     => params,
                      :template   => template,
                      :controller => self
      end
    end
  
  end
end