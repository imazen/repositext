class Repositext
  class Merge
    class AcceptedCorrectionsIntoContentAt

      # Auto-merges accepted_corrections into content_at.
      # @param[String] accepted_corrections
      # @param[String] content_at to merge corrections into
      # @param[String] content_at_filename
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge_auto(accepted_corrections, content_at, content_at_filename)
        corrections = extract_corrections(accepted_corrections)
        validate_corrections(corrections)
        outcome = merge_corrections_into_content_at(:auto, corrections, content_at, content_at_filename)
      end

      # Manually merges accepted_corrections into content_at.
      # @param[String] accepted_corrections
      # @param[String] content_at to merge corrections into
      # @param[String] content_at_filename
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge_manually(accepted_corrections, content_at, content_at_filename)
        corrections = extract_corrections(accepted_corrections)
        validate_corrections(corrections)
        outcome = merge_corrections_into_content_at(:manual, corrections, content_at, content_at_filename)
      end

    protected

      # @param[String] accepted_corrections
      # @return[Array<Hash>] a hash describing the corrections
      def self.extract_corrections(accepted_corrections)
        corrections = []
        s = StringScanner.new(accepted_corrections)
        while !s.eos? do
          ca = {}
          # Advance cursor up to and excluding next numbered correction
          s.skip_until(/\n(?=\d+\.)/)
          # capture correction number
          correction_number = s.scan(/\d+/)
          ca[:correction_number] = correction_number  if correction_number
          # capture remainder of numbered correction's first line
          correction_location = s.scan(/\.[^\n]+/)
          if correction_location
            # extract paragraph number
            ca[:paragraph_number] = correction_location.match(/paragraphs?\s+(\d+)/i)[1].to_s
            # extract line number
            ca[:line_number] = correction_location.match(/lines?\s+([\d\-]+)/i)[1].to_s
            # extract reads
            s.skip_until(/\nreads:\s+/i) # advance up to and including reads: marker
            ca[:before] = s.scan(/.+?(?=\nbecomes:)/im).to_s.strip # fetch everything up to "Becomes:"
            # extract becomes
            s.skip_until(/\nbecomes:\s+/i) # advance up to and including becomes: marker
            ca[:after] = s.scan(/.+?(?=(\n{2,}\d+\.|\n+\z))/m).to_s.strip # fetch up to next correction number, or end of document
          else
            # No more corrections found
            s.terminate
          end
          corrections << ca  if !ca.empty?
        end
        corrections
      end

      # Validates the extracted corrections
      # @param[Array<Hash>]
      def self.validate_corrections(corrections)
        # Validate that each correction has the required attrs
        with_missing_attrs = []
        corrections.each { |e|
          has_missing_attrs = [
            :correction_number,
            :paragraph_number,
            :line_number,
            :before,
            :after,
          ].any? { |attr| e[attr].nil? }
          if has_missing_attrs
            with_missing_attrs << e
          end
        }
        if with_missing_attrs.any?
          raise "Not all attrs are present: #{ with_missing_attrs.inspect }"
        end

        # Validate that we get consecutive correction_numbers
        correction_numbers = corrections.map { |e| e[:correction_number].to_i }.sort
        correction_numbers.each_cons(2) { |x,y|
          if y != x + 1
            raise "Correction numbers are not consecutive: #{ [x,y].inspect }"
          end
        }

        # Validate that no invalid characters are in correction file
        invalid_chars_regex = /–/
        corrections.each { |e|
          if e[:before] =~ invalid_chars_regex
            raise "Invalid character in correction ##{ e[:correction_number] }: #{ e[:before] }"
          end
          if e[:after] =~ invalid_chars_regex
            raise "Invalid character in correction ##{ e[:correction_number] }: #{ e[:before] }"
          end
        }
      end

      # Merges corrections into content_at
      # @param[Symbol] strategy one of :auto, :manual
      # @param[Array<Hash>] corrections
      # @param[String] content_at
      # @param[String] content_at_filename
      # @return[Outcome] where result is corrected_at and messages contains the report_lines
      def self.merge_corrections_into_content_at(strategy, corrections, content_at, content_at_filename)
        report_lines = []
        corrected_at = content_at.dup
        corrections.each { |correction|
          # count exact matches
          number_of_exact_matches = corrected_at.scan(correction[:before]).length
          if 0 == number_of_exact_matches && :manual == strategy
            # No exact matches found, try fuzzy match
            try_fuzzy_match!(
              correction,
              corrected_at,
              report_lines,
              content_at_filename
            )
          elsif 1 == number_of_exact_matches && :auto == strategy
            # There is exactly one perfect match, replace it automatically
            replace_perfect_match!(correction, corrected_at, report_lines)
          elsif :manual == strategy
            # Multiple matches
            pick_from_multiple_matches!(correction, corrected_at, report_lines, content_at_filename)
          end
        }
        Outcome.new(true, corrected_at, report_lines)
      end

      # This method is called when no perfect matches can be found.
      # @param[Hash] correction
      # @param[String] corrected_at will be updated in place
      # @param[Array] report_lines collector for report output
      # @param[String] content_at_filename filename of the content_at file
      def self.try_fuzzy_match!(correction, corrected_at, report_lines, content_at_filename)
        # Check if correction was already applied to the relevant paragraph
        # Extract relevant paragraph
        or_match_on_eagle = if compute_first_para_num(corrected_at) == correction[:paragraph_number].to_s
          # Don't stop at eagle when looking for paragraph 1, because it would stop at the starting eagle
          ''
        else
          # Stop also at eagle in case we're looking at the last paragraph that doesn't have a subsequent one
          '|'
        end
        # Capture more than a single paragraph for corrections that span paragraph boundaries
        how_many_paras_to_match = (correction[:after].scan('*{: .pn}').size) + 1
        stop_para_number = how_many_paras_to_match.times.each.inject(correction[:paragraph_number]) { |m,e| m.succ }
        relevant_paragraphs = corrected_at.match(
          /
            #{ dynamic_paragraph_number_regex(correction[:paragraph_number], corrected_at) } # match paragraph number span
            .*? # match anything nongreedily
            (?=(
              #{ dynamic_paragraph_number_regex(stop_para_number, corrected_at) } # stop before next paragraph number
              #{ or_match_on_eagle }
            ))
          /xm # multiline
        ).to_s
        if '' == relevant_paragraphs
          raise "Could not find paragraph #{ correction[:paragraph_number] }"
        end

        # Look for exact match
        if 1 == relevant_paragraphs.scan(correction[:after]).size
          l = "##{ correction[:correction_number] }: It appears that this correction has already been applied. (Exact)"
          report_lines << l
          $stderr.puts l
          return
        end

        # Try fuzzy match: Remove gap_marks and subtitle_marks and see if that was applied already
        correction_after_without_marks = correction[:after].gsub(/[%@]/, '')
        corrected_at_without_marks = relevant_paragraphs.gsub(/[%@]/, '')
        possible_matches_count = corrected_at_without_marks.scan(correction_after_without_marks).size
        if 1 == possible_matches_count
          l = "##{ correction[:correction_number] }: It appears that this correction has already been applied. (Except gap_mark or subtitle_mark)"
          report_lines << l
          $stderr.puts l
          return
        end

        # No match found, open location in sublime
        l = "##{ correction[:correction_number] }: #{ possible_matches_count > 1 ? 'Multiple matches' : 'No match' } found, update manually."
        report_lines << l
        $stderr.puts l
        open_in_sublime(
          content_at_filename,
          [
            "    Could not find phrase '#{ correction[:before] }'",
            "    in paragraph #{ correction[:paragraph_number] }, line #{ correction[:line_number] }",
            "    Replace with: '#{ correction[:after] }'",
          ].join("\n"),
          compute_line_number_from_paragraph_number(correction[:paragraph_number], corrected_at)
        )
      end

      def self.replace_perfect_match!(correction, corrected_at, report_lines)
        corrected_at.gsub!(correction[:before], correction[:after])
        l = "##{ correction[:correction_number] }: Found exact match and updated automatically."
        report_lines << l
        $stderr.puts l
      end

      # @param[String] content_at_filename filename of the content_at file
      def self.pick_from_multiple_matches!(correction, corrected_at, report_lines, content_at_filename)
        l = "##{ correction[:correction_number] }: Multiple matches found."
        report_lines << l
        $stderr.puts l
        open_in_sublime(
          content_at_filename,
          [
            "    Found multiple instances of phrase '#{ correction[:before] }'",
            "    in paragraph #{ correction[:paragraph_number] }, line #{ correction[:line_number] }",
            "    Replace with: '#{ correction[:after] }'",
          ].join("\n"),
          compute_line_number_from_paragraph_number(correction[:paragraph_number], corrected_at)
        )
      end

      # Given txt and paragraph_number, returns the line at which paragraph_number starts
      # @param[Integer, String] paragraph_number
      # @param[String] txt
      def self.compute_line_number_from_paragraph_number(paragraph_number, txt)
        regex = /
          .*? # match anything nongreedily
          #{ dynamic_paragraph_number_regex(paragraph_number, txt) } # match paragraph number span
        /xm # multiline
        text_before_paragraph = txt.match(regex).to_s
        line_number = text_before_paragraph.count("\n") + 1
      end

      # Opens filename in sublime and places cursor at line and col
      def self.open_in_sublime(filename, console_instructions, line=nil, col=nil)
        location_spec = [filename, line, col].compact.map { |e| e.to_s.strip }.join(':')
        $stderr.puts console_instructions
        `subl --wait --new-window #{ location_spec }`
      end

      # Dynamically generates a regex that matches pararaph_number
      # @param[Integer, String] paragraph_number
      # @param[String] txt the containing text, used to determine the first paragraph number (may not be 1)
      def self.dynamic_paragraph_number_regex(paragraph_number, txt)
        if compute_first_para_num(txt) == paragraph_number.to_s
          # Para 1 doesn't have a number, match beginning of document
          /\A/
        else
          /\n\*#{ paragraph_number.to_s.strip }\*\{\:\s\.pn\}/
        end
      end

      # Returns the number of the first paragraph. Normally '1', however there
      # are exceptions.
      def self.compute_first_para_num(txt)
        (txt.match(/\n\*(\d+)\*\{\:\s\.pn\}/)[1].to_s.to_i - 1).to_s
      end

    end
  end
end
