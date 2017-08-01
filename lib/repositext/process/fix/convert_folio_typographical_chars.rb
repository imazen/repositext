class Repositext
  class Process
    class Fix
      # Converts certain characters in text to proper typographical marks.
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      class ConvertFolioTypographicalChars

        # @param text [String]
        # @param filename [String]
        # @return [Outcome]
        def self.fix(text, filename, language)
          # TODO: Update this to use language specific chars language.chars[:apostrophe]
          text = text.dup
          convert_elipses!(text, language)
          convert_em_dashes!(text, language)
          convert_apostrophes!(text, language)
          convert_quotes!(text, language)
          unconvert_quotes_in_ials!(text, language)
          Outcome.new(true, { contents: text }, [])
        end

        # Reverses the changes from `.fix`. This is used for round-trip testing
        # of imported documents.
        # @param text [String]
        # @param language [Language]
        # @return [Outcome]
        def self.unfix(text, language)
          text = text.dup
          [
            [:elipsis, '...'],
            [:em_dash, "--"],
            [:d_quote_open, '"'],
            [:d_quote_close, '"'],
            [:apostrophe, "'"],
            [:s_quote_open, "'"],
            [:s_quote_close, "'"],
          ].each do |match, replacement|
            text.gsub!(language.chars[match], replacement)
          end
          Outcome.new(true, { contents: text }, [])
        end

        # Converts elipses in text in place
        # @param text [String]
        # @param language [Language]
        def self.convert_elipses!(text, language)
          text.gsub!(/(Mrs?\.)\.\.\./i, '\1' + language.chars[:elipsis]) # Abbreviations are valid instances we need to handle
          text.gsub!(/\.{3}(?!\.)/, language.chars[:elipsis]) # Replace 3, but not 4 dots with ellipsis
        end

        # Converts em dashes in text in place
        # @param text [String]
        # @param language [Language]
        def self.convert_em_dashes!(text, language)
          text.gsub!(/\-\-/, language.chars[:em_dash])
        end

        # Converts apostrophes in text in place
        # NOTE: This is a rule of thumb and doesn't work 100%.
        # It was used during initial import to convert as many as possible.
        # Manual cleanup was required after.
        # @param text [String]
        # @param language [Language]
        def self.convert_apostrophes!(text, language)
          # words with omitted leading characters (e.g., `'cause` for `because`)
          text.gsub!(/(?<=\W)'(cause|course|fore|kinis|less|till)\b/i, language.chars[:apostrophe] + '\1')
          # time period references (`'77`, `80's`, `1800's`)
          text.gsub!(/'(?=\d\d\b)/, language.chars[:apostrophe])
          text.gsub!(/\b(\d{1,4})'(?=s\b)/i, '\1' + language.chars[:apostrophe])
          # all words with apostrophes inside (this one is a fairly generic rule that may affect unwanted places)
          text.gsub!(/(?<=[[:alpha:]])'(?=[[:alpha:]])/, language.chars[:apostrophe])
          text.gsub!(/(?<=\.)'(?=s)/, language.chars[:apostrophe]) # e.g., `M.D.'s`
        end

        # Converts quotes in text in place
        # @param text [String]
        # @param language [Language]
        def self.convert_quotes!(text, language)
          alnum_ = '[:alnum:]'
          close_ = '\)\]' # I leave out curly braces since we don't want to convert double quotes in IALs to typographic ones
          newline_ = '\n'
          open_ = '\(\[' # I leave out curly braces (see above)
          # ImplementationTag #punctuation_characters
          punctuation_ = '\.\,\;\:\?\!'
          quote_right_ = "\"'#{ [language.chars[:d_quote_close], language.chars[:s_quote_close]].uniq }"
          separator_ = "\\*—\\-#{ language.chars[:elipsis] }"
          space_ = '\ \t'
          ellquell_ = '…?…'

          double_quote_spec = {
            :char => '"',
            :substitute_open => language.chars[:d_quote_open],
            :substitute_close => language.chars[:d_quote_close]
          }
          single_quote_spec = {
            :char => "'",
            :substitute_open => language.chars[:s_quote_open],
            :substitute_close => language.chars[:s_quote_close]
          }

          # Handle nested quotes first (this is the most specific case)
          nested_sequence = [double_quote_spec, single_quote_spec, double_quote_spec, single_quote_spec]
          # go from 4 to 2 levels of nesting
          [4,3,2].each do |nesting_level|
            quote_specs_for_nesting_level = nested_sequence.take(nesting_level)
            [quote_specs_for_nesting_level, quote_specs_for_nesting_level.reverse].each do |direction|
              # Nested opening quotes
              before = [newline_, open_, space_].uniq.join
              after = [alnum_, open_, separator_].uniq.join
              text.gsub!(
                /(?<=[#{ before }])#{ direction.map { |e| e[:char] }.join }(?=[#{ after }])/,
                direction.map { |e| e[:substitute_open] }.join
              )
              # Nested closing quotes
              before = [alnum_, close_, punctuation_, separator_].uniq.join
              after = [close_, newline_, punctuation_, space_, language.chars[:em_dash]].uniq.join
              text.gsub!(
                /(?<=[#{ before }])#{ direction.map { |e| e[:char] }.join }(?=[#{ after }])/,
                direction.map { |e| e[:substitute_close] }.join
              )
            end
          end

          quote_replacer = Proc.new { |txt, bef, aft, qs, substitute_key|
            txt.gsub!(
              /(?<=[#{ bef }])#{ qs[:char] }(?=[#{ aft }])/,
              qs[substitute_key]
            )
          }

          [double_quote_spec, single_quote_spec].each { |quote_spec|
            # Opening quotes
            before = [close_, newline_, open_, separator_, space_].uniq.join
            after = alnum_
            quote_replacer.call(text, before, after, quote_spec, :substitute_open)

            before = [space_, newline_].uniq.join
            after = [open_, punctuation_, separator_].uniq.join
            quote_replacer.call(text, before, after, quote_spec, :substitute_open)

            before = [open_].uniq.join
            after = [open_, punctuation_, separator_, space_].uniq.join
            quote_replacer.call(text, before, after, quote_spec, :substitute_open)

            before = [space_].uniq.join
            after = language.chars[:apostrophe] # Words like ’cause at beginning of a quote
            quote_replacer.call(text, before, after, quote_spec, :substitute_open)

            # Closing quotes
            before =  alnum_
            after = [close_, newline_, open_, punctuation_, separator_, space_].uniq.join
            quote_replacer.call(text, before, after, quote_spec, :substitute_close)

            # Editors notes
            text.gsub!(/#{ quote_spec[:char] }(?=—Ed\.\])/, quote_spec[:substitute_close])

            before = [close_, punctuation_, separator_].uniq.join
            after = [close_, newline_, punctuation_, space_].uniq.join
            quote_replacer.call(text, before, after, quote_spec, :substitute_close)

            after = [close_, newline_, punctuation_].uniq.join
            text.gsub!(
              /#{ quote_spec[:char] }(?=[#{ after }])/,
              quote_spec[:substitute_close]
            )

            before = [punctuation_, separator_, space_].uniq.join
            after = close_
            quote_replacer.call(text, before, after, quote_spec, :substitute_close)

            before = [punctuation_, close_, separator_, ellquell_].uniq.join
            after = ellquell_
            quote_replacer.call(text, before, after, quote_spec, :substitute_close)

            before = punctuation_
            after = language.chars[:em_dash]
            quote_replacer.call(text, before, after, quote_spec, :substitute_close)

            # Close to end of line
            after = [close_, punctuation_, quote_right_, separator_, space_].uniq.join
            text.gsub!(
              /#{ quote_spec[:char] }(?=[#{ after }]+#{ newline_ })/,
              quote_spec[:substitute_close]
            )
          }
        end

        # During the above steps we convert some straight double quotes inside IALs
        # to typographic ones. We need to undo that here.
        # @param text [String]
        # @param language [Language]
        def self.unconvert_quotes_in_ials!(text, language)
          text.gsub!(
            /
              (?<=\{) # preceded by opening brace
              ([^\{\}]*) # capture any leading non-brace chars
              [#{ language.chars[:d_quote_close] + language.chars[:d_quote_open] }] # capture any typographic double quote
              ([^\{\}]*) # capture any trailing non-brace chars
              (?=\}) # followed by closing brace
            /x,
            '\1"\2' # keep leading and trailing non-brace chars, replace typographic quote with straight
          )
        end

      end
    end
  end
end
