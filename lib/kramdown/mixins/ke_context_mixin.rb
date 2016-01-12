module Kramdown
  module KeContextMixin

    include ::Kramdown::RawTextParser

    # Adds the_text to current_text_container, creating a new text
    # element if necessary. Entity encodes allowed unicode characters.
    # @param the_text [String]
    # @param xn [Nokogiri::XML::Node] for warning location
    def add_text_to_current_text_container(the_text, xn)
      if(ctce = get_current_text_container(xn))
        process_and_add_text(the_text, ctce, :text)
      end
    end

    # Returns value of attr_name, raises warning if attr_name returns nil
    # @param attr_name [String]
    # @param xn [Nokogiri::XML::Node] for warning location info
    # @param warn_if_nil [Boolean, optional] generate warning if desired attr is nil
    def get(attr_name, xn, warn_if_nil=true)
      if (v = @cx[attr_name.to_s]).nil? && warn_if_nil
        @parser.add_warning(xn, "#{ attr_name } is nil.")
      end
      v
    end

    # Returns the current text container from stack
    # @param [Nokogiri::XML::Node] xn for warning location
    def get_current_text_container(xn)
      get('text_container_stack', xn).last
    end

    # Replaces current text container with new_text_container
    # @param new_text_container_ke [Kramdown::ElementRt]
    # @return [Kramdown::ElementRt] the previous text container
    def replace_current_text_container_with(new_text_container_ke)
      prev_text_container = @cx['text_container_stack'].pop
      @cx['text_container_stack'].push(new_text_container_ke)
      prev_text_container
    end

    # Set a ke_context attribute
    # @param [String] attr_name
    # @param [Object] attr_value
    def set(attr_name, attr_value)
      @cx[attr_name.to_s] = attr_value
    end

    # Adds an attribute to current p's IAL. Raises warning if p is nil.
    # @param xn [Nokogiri::XML::Node] the xn that wanted to access current p
    # @param attr_name [String]
    # @param attr_value [Object]
    def set_attr_on_p(xn, attr_name, attr_value)
      if @cx['p'].nil?
        @parser.add_warning(xn, 'No containing p')
        return false
      end
      @cx['p'].attr[attr_name] = attr_value
    end

    # Manages the text_container_stack around processing of an XML node
    # @param new_text_container_ke [Kramdown::ElementRt]
    def with_text_container_stack(new_text_container_ke)
      @cx['text_container_stack'].push(new_text_container_ke)
      yield
    ensure
      @cx['text_container_stack'].pop
    end

  end
end
