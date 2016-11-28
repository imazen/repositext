module Kramdown
  # Provides a stack for kramdown elements.
  # Decorates Array class with stack related methods.
  class ElementStack < Array

    def inside_id_title1?
      detect { |e| :p == e.type && e.has_class?('id_title1') }
    end

    def inside_id_title2?
      detect { |e| :p == e.type && e.has_class?('id_title2') }
    end

    def inside_title?
      detect { |e| :header == e.type }
    end

  end
end
