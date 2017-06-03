class Repositext
  class Process
    class Fix
      # Some cyrillic files have invalid latin characters in them. They need to
      # be replaced with the equivalent (same-looking) cyrillic characters.
      # However we don't want to replace any English words.
      # So we just replace single instances of characters and only report runs
      # of latin characters (likely words) to be manually reviewed and fixed.
      class ReplaceLatinWithCyrillicCharacters

        LATIN_TO_CYRILLIC_MAP = {
          "A" => "А",
          "a" => "а",
          "B" => "В",
          "C" => "С",
          "c" => "с",
          "E" => "Е",
          "e" => "е",
          "H" => "Н",
          "I" => "І",
          "j" => "ј",
          "J" => "Ј",
          "K" => "К",
          "M" => "М",
          "O" => "О",
          "o" => "о",
          "P" => "Р",
          "p" => "р",
          "S" => "Ѕ",
          "s" => "ѕ",
          "T" => "Т",
          "V" => "Ѵ",
          "v" => "ѵ",
          "X" => "Х",
          "x" => "х",
          "Y" => "У",
          "y" => "у",
          "ë" => "ё",
          "Ï" => "Ї",
          "ï" => "ї",
        }

        # @param content_at_contents [String]
        # @param filename [String] for location reporting
        # @return [Outcome] with
        #   `{ contents: new_contents, latin_chars_that_were_not_replaced: [] }`
        #   as result.
        def self.fix(content_at_contents, filename)
          new_contents = ""
          latin_chars_that_were_not_replaced = []
          latin_chars = LATIN_TO_CYRILLIC_MAP.keys | []

          # Separate id_page out
          cat_wo_id, id_page = Repositext::Utils::IdPageRemover.remove(content_at_contents)

          ial_rx = /\{[^\}]*\}/
          # Upper case ASCII, lower case ASCII, extended latin-1 letters
          latin_char_rx = /[\x41-\x5A\x61-\x7A\u00C0-\u00FE]/
          # dependency boundary
          isolated_latin_char_rx = /(?<!#{ latin_char_rx })#{ latin_char_rx }(?!#{ latin_char_rx })/
          multi_latin_chars_rx = /#{ latin_char_rx }{2,}/


          s = StringScanner.new(cat_wo_id)
          while !s.eos? do
            # Regexes go from specific to general
            if ial = s.scan(ial_rx)
              # Keep IAL as is
              new_contents << ial
            elsif isolated_latin_char = s.scan(isolated_latin_char_rx)
              # Replace with equivalent cyrillic char, raise if no match found
              ce = LATIN_TO_CYRILLIC_MAP[isolated_latin_char]
              if ce.nil?
                # Keep as is
                new_contents << isolated_latin_char
                # Report this unmapped char as not replaced
                latin_chars_that_were_not_replaced << {
                  filename: filename,
                  line: new_contents.count("\n") + 1,
                  latin_chars: isolated_latin_char,
                  reason: "No mapping for this character provided."
                }
              else
                # Replace latin with cyrillic char
                new_contents << ce
              end
            elsif multi_latin_chars = s.scan(multi_latin_chars_rx)
              # Keep as is
              new_contents << multi_latin_chars
              # Report any runs of latin chars for manual review
              latin_chars_that_were_not_replaced << {
                filename: filename,
                line: new_contents.count("\n") + 1,
                latin_chars: multi_latin_chars,
                reason: "Sequence of multiple latin chars, may be English word."
              }
            else
              # take next char as is
              new_contents << s.getch
            end
          end

          Outcome.new(
            true,
            {
              contents: new_contents + id_page,
              lctwnr: latin_chars_that_were_not_replaced
            },
            []
          )
        end

      end
    end
  end
end
