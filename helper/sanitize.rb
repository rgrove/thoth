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
