module Ramaze  
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
    
    def error_404
      error_layout 404, '404 Not Found', %[
        <p>
          The requested URL <code>#{h(request.REQUEST_URI)}</code> was not
          found on this server.
        </p>
      ]
    end
    
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
