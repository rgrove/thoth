module Ramaze  
  
  # The ErrorHelper module provides methods for interrupting the current request
  # and responding with an error message and corresponding HTTP error code.
  module ErrorHelper
    def error_layout(status, title, content = '')
      respond %[
        <html>
          <head>
            <title>#{h(title)}</title>
          </head>
          <body>
            <h1>#{h(title)}</h1>
            #{content}
          </body>
        </html>
      ].unindent, status
    end
    
    # Displays a "404 Not Found" error message and returns a 404 response code.
    def error_404
      error_layout 404, '404 Not Found', %[
        <p>
          The requested URL <code>#{h(request.REQUEST_URI)}</code> was not
          found on this server.
        </p>
      ]
    end
    
    # Displays a "500 Internal Server Error" error message and returns a 500
    # response code.
    def error_500
      error_layout 500, '500 Internal Server Error', %[
        <p>
          The server encountered an internal error and was unable to complete
          your request.
        </p>
      ]
    end
  end  

end
