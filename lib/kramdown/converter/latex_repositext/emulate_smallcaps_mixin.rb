module Kramdown
  module Converter
    class LatexRepositext
      # Namespace for methods related to emulating smallcaps
      module EmulateSmallcapsMixin

        # Since our font doesn't have a small caps variant, we have to emulate it
        # for latex.
        # We wrap all groups of lower case characters in the \RtSmCapsEmulation command.
        # We apply custom kerning at the beginning and end of each smallcaps
        # emulated span since Latex' regular kerning doesn't work there.
        # We even apply inter-word kerning to characters that are separated by a space.
        #
        # @param txt [String] the text inside the em.smcaps.
        # @param font_name [String]
        # @param font_attrs [Array<String>]
        # @return [String]
        def emulate_small_caps(txt, font_name, font_attrs)
          debug = false

          if debug
            puts
            p txt
            p [font_name, font_attrs]
          end

          if txt =~ /\A[[:alpha:]]\z/
            # This is a single character, part of a date code
            return %(\\RtSmCapsEmulation{none}{#{ txt.unicode_upcase }}{none})
          end

          new_string = ""
          font_attrs = font_attrs.compact.sort.join(' ')
          str_sc = StringScanner.new(txt)

          str_sc_state = :start
          keep_scanning = true

          while keep_scanning do
            puts  if :start == str_sc_state && debug
            puts("#{ str_sc_state.inspect } - #{ str_sc.rest.inspect }")  if debug
            case str_sc_state
            when :start
              leading_chars = nil
              smallcaps_chars = nil
              immediately_following_char = nil
              squeezed_following_char = nil

              leading_kerning_value = nil
              trailing_kerning_value = nil

              str_sc_state = :capture_leading_chars
            when :capture_leading_chars
              if str_sc.scan(/\s+/)
                # Consume leading space chars.
                new_string << str_sc.matched
                puts("  #{ str_sc.matched.inspect }")  if debug
              elsif str_sc.scan(/[^[:lower:]\s]+/)
                # Capture leading non-lowercase chars.
                leading_chars = str_sc.matched
                new_string << leading_chars
                puts("  #{ leading_chars.inspect }")  if debug
              end
              str_sc_state = :capture_smallcaps_chars
            when :capture_smallcaps_chars
              # Capture lowercase chars for smallcaps emulation.
              if(str_sc.scan(/[[:lower:]]+/))
                smallcaps_chars = str_sc.matched
                puts("  #{ smallcaps_chars.inspect }")  if debug
              end
              str_sc_state = :detect_following_char
            when :detect_following_char
              # Peek at the following char (even if separated by space).
              if(str_sc.check(/\s?./))
                immediately_following_char = str_sc.matched.first.strip[0] # nil or other char
                squeezed_following_char = str_sc.matched.strip # other char
                if debug
                  puts "  immediately_following_char: #{ immediately_following_char.inspect }"
                  puts("  squeezed_following_char: #{ squeezed_following_char.inspect }")
                end
              end
              str_sc_state = :finalize_smcaps_run
            when :finalize_smcaps_run
              # Process the string: apply custom kernings and wrap in smallcaps emulation command
              prev_char = (leading_chars || '')[-1]
              if prev_char && smallcaps_chars
                # Determine leading custom kerning
                leading_character_pair = [prev_char, smallcaps_chars[0]].join
                puts("  leading character pair: #{ leading_character_pair.inspect }")  if debug
                leading_kerning_value = smallcaps_kerning_map.lookup_kerning(
                  font_name,
                  font_attrs,
                  leading_character_pair
                )
                if leading_kerning_value
                  # We have a value, add `em` unit
                  leading_kerning_value = "#{ leading_kerning_value }em"
                else
                  # No kerning value, print out warning
                  puts "Unhandled Kerning for font #{ font_name.inspect }, font_attrs #{ font_attrs.inspect } and character pair #{ leading_character_pair.inspect }, ".color(:red)
                end
              end
              # Determine trailing custom kerning
              end_char = (smallcaps_chars || leading_chars || '')[-1]
              if end_char && squeezed_following_char
                trailing_character_pair = [end_char, squeezed_following_char].join
                puts("  trailing character pair: #{ trailing_character_pair.inspect }")  if debug
                trailing_kerning_value = smallcaps_kerning_map.lookup_kerning(
                  font_name,
                  font_attrs,
                  trailing_character_pair
                )
                if trailing_kerning_value
                  # We have a value, add `em` unit
                  trailing_kerning_value = "#{ trailing_kerning_value }em"
                else
                  # No kerning value, print out warning
                  puts "Unhandled Kerning for font #{ font_name.inspect }, font_attrs #{ font_attrs.inspect } and character pair #{ trailing_character_pair.inspect }, ".color(:red)
                end
              end

              if smallcaps_chars || leading_kerning_value || trailing_kerning_value
                if leading_chars && smallcaps_chars
                  # prevent linebreak between leading_chars and smallcaps_chars
                  new_string << "\\RtNoLineBreak{}"
                end
                new_string << [
                  %(\\RtSmCapsEmulation), # latex command
                  %({#{ leading_kerning_value || 'none' }}), # leading custom kerning argument
                  %({#{ (smallcaps_chars || '').unicode_upcase }}), # text in smallcaps
                  %({#{ trailing_kerning_value || 'none' }}), # trailing custom kerning argument
                ].join
                if immediately_following_char
                  # prevent linebreak between smallcaps_chars and immediately following char
                  new_string << "\\RtNoLineBreak{}"
                end
              end
              if str_sc.eos?
                keep_scanning = false
              else
                str_sc_state = :start
              end
              puts("  new string: #{ new_string.inspect }")  if debug
            else
              raise "Handle this: #{ str_sc_state.inspect }"
            end
          end
          new_string
        end

        # @return [Hash]
        def smallcaps_kerning_map
          @smallcaps_kerning_map ||= SmallcapsKerningMap.new
        end

      end
    end
  end
end
