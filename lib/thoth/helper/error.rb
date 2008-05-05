#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
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

  # The Error helper module provides methods for interrupting the current
  # request and responding with an error message and corresponding HTTP error
  # code.
  module Error
    Helper::LOOKUP << self

    # Displays an error backtrace.
    def error
      error_500 unless Thoth.trait[:mode] == :devel
      response['Content-Type'] = 'text/html'
      Ramaze::Action.current.template ||= Thoth::VIEW_DIR/'error.rhtml'
      super
    end

    # Displays a "403 Forbidden" error message and returns a 403 response code.
    def error_403
      error_layout 403, '403 Forbidden', %[
        <p>
          You don't have permission to access
          <code>#{h(request.REQUEST_URI)}</code> on this server.
        </p>
      ]
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

    private

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
  end

end; end
