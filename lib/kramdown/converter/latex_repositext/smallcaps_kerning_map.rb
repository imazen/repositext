module Kramdown
  module Converter
    class LatexRepositext
      # Manages the kerning map for smallcaps emulation: Loads map from file and provides
      # lookup functionality.
      class SmallcapsKerningMap

        include KerningSampleLatexMixin

        class UnhandledFontError < ::StandardError; end
        class UnhandledFontAttributeError < ::StandardError; end
        class UnhandledCharacterPairError < ::StandardError; end

        attr_reader :kerning_map

        def self.smallcaps_kerning_map_file_path
          File.expand_path("../../../../../data/smallcaps_kerning_map.json", __FILE__)
        end

        def initialize(kerning_map_override=nil)
          @kerning_map = (
            kerning_map_override or
            JSON.load(
              File.read(
                self.class.smallcaps_kerning_map_file_path
              )
            )
          )
        end

        # Looks up the kerning value for font_name and character_pair.
        # Raises an exception if either of the two is not handled.
        # @param font_name [String]
        # @param character_pair [String] two characters, e.g., "Wa"
        # @return [Float] the kerning value in Latex em units, or nil.
        def lookup_kerning(font_name, font_attribute, character_pair, raise_unhandled_exceptions=false)
          kerning_values_map = @kerning_map['kerning_values']
          font_map = kerning_values_map[font_name]
          if font_map.nil?
            if raise_unhandled_exceptions
              raise UnhandledFontError.new("Unhandled font: #{ font_name.inspect }")
            else
              return nil
            end
          end
          font_attribute_map = font_map[font_attribute]
          if font_attribute_map.nil?
            if raise_unhandled_exceptions
              raise UnhandledFontAttributeError.new("Unhandled font attribute: #{ font_attribute.inspect } for font #{ font_name.inspect }")
            else
              return nil
            end
          end
          cp_kerning = font_attribute_map[sanitize_character_pair(character_pair, @kerning_map['character_mappings'])]
          if cp_kerning.nil?
            if raise_unhandled_exceptions
              raise UnhandledCharacterPairError.new(
                "Unhandled character pair: #{ character_pair.inspect } for font #{ font_name.inspect } and attribute #{ font_attribute.inspect }."
              )
            else
              return nil
            end
          end
          cp_kerning
        end

      protected

        # Processes character_pair to be fit for map lookup. The character map
        # only contains upper case chars, so we have to do some upper/lowercase
        # conversion to get the right mappint.
        # @param character_pair [String]
        # @param character_mappings [Hash{String => String}]
        # @return [String]
        def sanitize_character_pair(character_pair, character_mappings)
          # Map special characters to their mappings
          character_pair.chars.map { |char|
            # Convert char to upper case for lookup since all keys in map are upper.
            upper_char = char.unicode_upcase
            # Use mapping if present, otherwise fall back to char
            r = character_mappings[upper_char]
            if r && char != upper_char
              # convert to lower case
              r = r.unicode_downcase
            end
            r ||= char
            r
          }.join
          # NOTE: Initially we thought we could just normalize the chars to ASCII,
          # however in order to be able to handle non-latin character sets, we
          # need an explicit map for accented characters to their baseline char
          # and leave characters from certain alphabets untouched, e.g., cyrillic.
          # character_pair.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/,'').to_s
        end

      end
    end
  end
end
