class Repositext
  class Fix
    class ConvertFolioTypographicalChars

      # Converts certain characters in text to proper typographical marks.
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # @param[String] text
      # @param[String] filename
      # @return[Outcome]
      def self.fix(text, filename)
        text = text.dup
        convert_elipses!(text)
        convert_em_dashes!(text)
        convert_apostrophes!(text)
        convert_quotes!(text)
        unconvert_quotes_in_ials!(text)
        Outcome.new(true, { contents: text }, [])
      end

      # Reverses the changes from `.fix`. This is used for round-trip testing
      # of imported documents.
      # @param[String] text
      # @return[Outcome]
      def self.unfix(text)
        text = text.dup
        text.gsub!(ELIPSIS, '...')
        text.gsub!(EM_DASH, "--")
        text.gsub!(D_QUOTE_OPEN, '"')
        text.gsub!(D_QUOTE_CLOSE, '"')
        text.gsub!(APOSTROPHE, "'")
        text.gsub!(S_QUOTE_OPEN, "'")
        text.gsub!(S_QUOTE_CLOSE, "'")
        Outcome.new(true, { contents: text }, [])
      end

      # Converts elipses in text in place
      # @param[String] text
      def self.convert_elipses!(text)
        text.gsub!(/(Mrs?\.)\.\.\./i, '\1' + ELIPSIS) # Abbreviations are valid instances we need to handle
        text.gsub!(/\.{3}(?!\.)/, ELIPSIS) # Replace 3, but not 4 dots with ellipsis
      end

      # Converts em dashes in text in place
      # @param[String] text
      def self.convert_em_dashes!(text)
        text.gsub!(/\-\-/, EM_DASH)
      end

      # Converts apostrophes in text in place
      # @param[String] text
      def self.convert_apostrophes!(text)
        # words with omitted leading characters (e.g., `'cause` for `because`)
        text.gsub!(/(?<=\W)'(cause|course|fore|kinis|less|till)\b/i, APOSTROPHE + '\1')
        # time period references (`'77`, `80's`, `1800's`)
        text.gsub!(/'(?=\d\d\b)/, APOSTROPHE)
        text.gsub!(/\b(\d{1,4})'(?=s\b)/i, '\1' + APOSTROPHE)
        # all words with apostrophes inside (this one is a fairly generic rule that may affect unwanted places)
        text.gsub!(/(?<=[[:alpha:]])'(?=[[:alpha:]])/, APOSTROPHE)
        text.gsub!(/(?<=\.)'(?=s)/, APOSTROPHE) # e.g., `M.D.'s`
      end

      # Converts quotes in text in place
      # @param[String] text
      def self.convert_quotes!(text)
        alnum_ = '[:alnum:]'
        close_ = '\)\]' # I leave out curly braces since we don't want to convert double quotes in IALs to typographic ones
        newline_ = '\n'
        open_ = '\(\[' # I leave out curly braces (see above)
        punctuation_ = '\.\,\;\:\?\!'
        quote_right_ = "\"'#{ D_QUOTE_CLOSE }#{ S_QUOTE_CLOSE }"
        separator_ = '\*—\-…'
        space_ = '\ \t'
        undiscernible_ = '…?…'

        double_quote_spec = { :char => '"', :substitute_open => D_QUOTE_OPEN, :substitute_close => D_QUOTE_CLOSE }
        single_quote_spec = { :char => "'", :substitute_open => S_QUOTE_OPEN, :substitute_close => S_QUOTE_CLOSE }

        # Handle nested quotes first (this is the most specific case)
        nested_sequence = [double_quote_spec, single_quote_spec, double_quote_spec, single_quote_spec]
        # go from 4 to 2 levels of nesting
        [4,3,2].each do |nesting_level|
          quote_specs_for_nesting_level = nested_sequence.take(nesting_level)
          [quote_specs_for_nesting_level, quote_specs_for_nesting_level.reverse].each do |direction|
            # Nested opening quotes
            before = [newline_, open_, space_].join
            after = [alnum_, open_, separator_].join
            text.gsub!(
              /(?<=[#{ before }])#{ direction.map { |e| e[:char] }.join }(?=[#{ after }])/,
              direction.map { |e| e[:substitute_open] }.join
            )
            # Nested closing quotes
            before = [alnum_, close_, punctuation_, separator_].join
            after = [close_, newline_, punctuation_, space_, EM_DASH].join
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
          before = [close_, newline_, open_, separator_, space_].join
          after = alnum_
          quote_replacer.call(text, before, after, quote_spec, :substitute_open)

          before = [space_, newline_].join
          after = [open_, punctuation_, separator_].join
          quote_replacer.call(text, before, after, quote_spec, :substitute_open)

          before = [open_].join
          after = [open_, punctuation_, separator_, space_].join
          quote_replacer.call(text, before, after, quote_spec, :substitute_open)

          before = [space_].join
          after = APOSTROPHE # Words like ’cause at beginning of a quote
          quote_replacer.call(text, before, after, quote_spec, :substitute_open)

          # Closing quotes
          before =  alnum_
          after = [close_, newline_, open_, punctuation_, separator_, space_].join
          quote_replacer.call(text, before, after, quote_spec, :substitute_close)

          # Editors notes
          text.gsub!(/#{ quote_spec[:char] }(?=—Ed\.\])/, quote_spec[:substitute_close])

          before = [close_, punctuation_, separator_].join
          after = [close_, newline_, punctuation_, space_].join
          quote_replacer.call(text, before, after, quote_spec, :substitute_close)

          after = [close_, newline_, punctuation_].join
          text.gsub!(
            /#{ quote_spec[:char] }(?=[#{ after }])/,
            quote_spec[:substitute_close]
          )

          before = [punctuation_, separator_, space_].join
          after = close_
          quote_replacer.call(text, before, after, quote_spec, :substitute_close)

          before = [punctuation_, close_, separator_, undiscernible_].join
          after = undiscernible_
          quote_replacer.call(text, before, after, quote_spec, :substitute_close)

          before = punctuation_
          after = EM_DASH
          quote_replacer.call(text, before, after, quote_spec, :substitute_close)

          # Close to end of line
          after = [close_, punctuation_, quote_right_, separator_, space_].join
          text.gsub!(
            /#{ quote_spec[:char] }(?=[#{ after }]+#{ newline_ })/,
            quote_spec[:substitute_close]
          )
        }
      end

      # During the above steps we convert some straight double quotes inside IALs
      # to typographic ones. We need to undo that here.
      # @param[String] text
      def self.unconvert_quotes_in_ials!(text)
        text.gsub!(/(?<=\{)([^\{\}]*)[#{ D_QUOTE_CLOSE + D_QUOTE_OPEN }]([^\{\}]*)(?=\})/, '\1"\2')
      end

    end
  end
end
