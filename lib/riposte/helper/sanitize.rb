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

require 'hpricot'

module Ramaze
  
  # The SanitizeHelper module provides a method for stripping dangerous elements
  # and attributes from user-supplied HTML based on element and attribute
  # whitelists.
  module SanitizeHelper
    private

    # Elements to allow in sanitized HTML.
    ELEMENTS = [
      'a', 'b', 'blockquote', 'br', 'code', 'dd', 'dl', 'dt', 'em', 'i', 'li',
      'ol', 'p', 'pre', 'small', 'strike', 'strong', 'sub', 'sup', 'u', 'ul'
    ]

    # Attributes to allow in sanitized HTML elements.
    ATTRIBUTES = {
      'a'   => ['href', 'title'],
      'pre' => ['class']
    }

    # Attributes that should be checked for valid protocols.
    PROTOCOL_ATTRIBUTES = {'a' => ['href']}

    # Valid protocols.
    PROTOCOLS = ['ftp', 'http', 'https', 'mailto']
    
    # Uses Hpricot to sanitize HTML based on element and attribute whitelists.
    # This is a more strict version of the method at
    # http://rid.onkulo.us/archives/14-sanitizing-html-with-ruby-and-hpricot
    def sanitize_html(html)
      # Turn <% and %> into entities to prevent arbitrary code execution via
      # Erubis.
      html.gsub!('<%', '&lt;%')
      html.gsub!('%>', '%&gt;')

      h = Hpricot(html)

      h.search('*').each do |el|
        if el.elem?
          tag = el.name.downcase

          if !ELEMENTS.include?(tag)
            # Delete any element that isn't in the whitelist.
            el.parent.replace_child(el, el.children)
          elsif ATTRIBUTES.has_key?(tag)
            # Delete any attribute that isn't in the whitelist for this
            # particular element.
            el.raw_attributes.delete_if do |key, val|
              !ATTRIBUTES[tag].include?(key.downcase)
            end

            # Check applicable attributes for valid protocols.
            if PROTOCOL_ATTRIBUTES.has_key?(tag)
              el.raw_attributes.delete_if do |key, val|
                PROTOCOL_ATTRIBUTES[tag].include?(key.downcase) &&
                    (!(val.downcase =~ /^([^:]+)\:/) || !PROTOCOLS.include?($1))
              end
            end
          else
            # Delete all attributes from elements with no whitelisted
            # attributes.
            el.raw_attributes = {}
          end
        elsif el.comment?
          # Delete all comments, since it's possible to make IE execute JS
          # within conditional comments.
          el.swap('')
        end
      end

      h.to_s
    end
  end
end
