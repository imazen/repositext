# This patch adds smallCaps and vertAlign text run attributes.
module Caracal

  # Patches to file caracal/core/models/text_model.rb
  module Core
    module Models
      class TextModel

        attr_reader :text_small_caps
        attr_reader :text_vert_align

        def run_attributes
          {
            font:       text_font,
            color:      text_color,
            size:       text_size,
            bold:       text_bold,
            italic:     text_italic,
            underline:  text_underline,
            bgcolor:    text_bgcolor,
            # Added attrs
            small_caps: text_small_caps,
            vert_align: text_vert_align,
          }
        end

        #=============== Add SETTERS for new attrs ==============================

        # booleans
        [:small_caps].each do |m|
          define_method "#{ m }" do |value|
            instance_variable_set("@text_#{ m }", !!value)
          end
        end

        # strings
        [:vert_align].each do |m|
          define_method "#{ m }" do |value|
            instance_variable_set("@text_#{ m }", value.to_s)
          end
        end

        private

        def option_keys
          [
            :content, :font, :color, :size, :bold, :italic, :underline, :bgcolor,
            # New attrs
            :small_caps, :vert_align
          ]
        end

      end

    end
  end

  # Patches to file caracal/renderers/document_renderer.rb
  module Renderers
    class DocumentRenderer

      private

      def render_run_attributes(xml, model, paragraph_level=false)
        if model.respond_to? :run_attributes
          attrs = model.run_attributes.delete_if { |k, v| v.nil? }

          if paragraph_level && attrs.empty?
            # skip
          else
            xml.send 'w:rPr' do
              unless attrs.empty?
                xml.send 'w:rStyle', { 'w:val'  => attrs[:style] }                            unless attrs[:style].nil?
                xml.send 'w:color',  { 'w:val'  => attrs[:color] }                            unless attrs[:color].nil?
                xml.send 'w:sz',     { 'w:val'  => attrs[:size]  }                            unless attrs[:size].nil?
                xml.send 'w:b',      { 'w:val'  => (attrs[:bold] ? '1' : '0') }               unless attrs[:bold].nil?
                xml.send 'w:i',      { 'w:val'  => (attrs[:italic] ? '1' : '0') }             unless attrs[:italic].nil?
                xml.send 'w:u',      { 'w:val'  => (attrs[:underline] ? 'single' : 'none') }  unless attrs[:underline].nil?
                xml.send 'w:shd',    { 'w:fill' => attrs[:bgcolor], 'w:val' => 'clear' }      unless attrs[:bgcolor].nil?
                # Patch JH: added smallCaps and vertAlign
                xml.send 'w:smallCaps', { 'w:val' => attrs[:small_caps] }  unless attrs[:small_caps].nil?
                xml.send 'w:vertAlign', { 'w:val' => attrs[:vert_align] }  unless attrs[:vert_align].nil?
                unless attrs[:font].nil?
                  f = attrs[:font]
                  xml.send 'w:rFonts', { 'w:ascii' => f, 'w:hAnsi' => f, 'w:eastAsia' => f, 'w:cs' => f }
                end
              end
              xml.send 'w:rtl',    { 'w:val' => '0' }
            end
          end
        end
      end

    end
  end
end
