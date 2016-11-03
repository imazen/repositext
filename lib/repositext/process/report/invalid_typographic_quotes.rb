class Repositext
  class Process
    class Report
      # Finds invalid quote sequences, e.g., two subsequent open double quotes.
      #
      # An invalid sequence is:
      # * two d-quote-open with no other quote (excluding apostrophe) or bracket-open
      #   inbetween on the same line. This allows for multi paragraph quotes where
      #   each subsequent paragraph starts with d-quote-open. It also allows for
      #   quotes inside editors notes (that may legitimately be nested inside an
      #   outer quote).
      # * two d-quote-close with no other quote (excluding apostrophe) or bracket-close
      #   inbetween. The same line constraint doesn't apply here. It allows for
      #   quotes inside editors notes (that may legitimately be nested inside an
      #   outer quote).
      # * two s-quote-open with no other quote (including apostrophe) inbetween.
      #   The same line constraint doesn't apply here.
      #
      # Note that s-quote-close is also used as apostrophe, and we could have
      # multiple of those in subsequent order without being invalid. So we can't
      # test for s-quote-close sequences.
      #
      # QuoteType is defined by single/double and open/close.
      class InvalidTypographicQuotes

        # Initialize a new report
        # @param context_size [Integer] how much context to provide around invalid quotes
        def initialize(context_size, language)
          @context_size = context_size
          @language = language
          @files_hash = {}
        end

        # Process a new file and its contents
        def process(contents, filename)
          str_sc = Kramdown::Utils::StringScanner.new(contents)
          while !str_sc.eos? do
            if(match = str_sc.scan_until(invalid_quotes_rx))
              quote_type = match[-1]
              excerpt = nil
              position_of_previous_quote = match.rindex(quote_type, -2) || 0
              if 0 == @context_size
                # include entire lines, including the preceding paragraph number,
                # don't truncate in the middle
                start_position = match.rindex(/\n[@%]*\*\d+\*\{: \.pn\}/, position_of_previous_quote) || 0
                excerpt = match[start_position..-1]
                text_until_following_newline = str_sc.check_until(/\n/) || ''
                excerpt << text_until_following_newline
              else
                # include @context_size chars before and after the quote pair
                # and truncate in the middle
                start_position = [position_of_previous_quote - @context_size, 0].max
                excerpt = match[start_position..-1]
                excerpt << str_sc.peek(@context_size)
                excerpt = excerpt.truncate_in_the_middle(120)
              end
              excerpt = excerpt.inspect
              excerpt.gsub!(/^"/, '') # Remove leading double quotes (from inspect)
              excerpt.gsub!(/"$/, '') # Remove trailing double quotes (from inspect)
              @files_hash[filename] ||= []
              @files_hash[filename] << {
                line: str_sc.current_line_number,
                excerpt: excerpt,
              }
            else
              break
            end
          end
        end

        # Returns the results of this report, grouped by filename
        def results
          @files_hash.to_a.sort { |a,b| a.first <=> b.first }
        end

      protected

        def apostrophe
          @language.chars[:apostrophe]
        end

        def d_quote_close
          @language.chars[:d_quote_close]
        end

        def d_quote_open
          @language.chars[:d_quote_open]
        end

        def s_quote_open
          @language.chars[:s_quote_open]
        end

        def straight_quotes
          %("').freeze
        end

        def newline
          %(\n).freeze
        end

        def bracket_close
          %(]).freeze
        end

        def bracket_open
          %([).freeze
        end

        def all_quotes_excluding_apostrophe
          [
            d_quote_close,
            d_quote_open,
            s_quote_open,
            straight_quotes
          ].join.freeze
        end

        def all_quotes_including_apostrophe
          [
            all_quotes_excluding_apostrophe,
            apostrophe,
          ].join.freeze
        end

        def invalid_quotes_rx
          /
            (?:
              #{ d_quote_open }
              [^#{ Regexp.escape(all_quotes_excluding_apostrophe + newline + bracket_open) }]*
              #{ d_quote_open }
            )
            |
            (?:
              #{ d_quote_close }
              [^#{ Regexp.escape(all_quotes_excluding_apostrophe + bracket_close) }]*
              #{ d_quote_close }
            )
            |
            (?:
              #{ s_quote_open }
              [^#{ Regexp.escape(all_quotes_including_apostrophe) }]*
              #{ s_quote_open }
            )
          /mx
        end

      end
    end
  end
end
