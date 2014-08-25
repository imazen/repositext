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
            # extract reads
            s.skip_until(/\nreads:\s+/i) # advance up to and including reads: marker
            ca[:before] = s.scan(/[^\n]+/).to_s.strip # fetch single line
            # extract becomes
            s.skip_until(/\nbecomes:\s+/i) # advance up to and including becomes: marker
            ca[:after] = s.scan(/[^\n]+/).to_s.strip # fetch single line
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
      end

      # Merges corrections into content_at
      # @param[Symbol] strategy one of :auto, :manual
      # @param[Array<Hash>] corrections
      # @param[String] content_at
      # @param[String] content_at_filename
      # @return[Outcome] where result is corrected_at and messages contains the report_lines
      def self.merge_corrections_into_content_at(strategy, corrections, content_at, content_at_filename)
        report_lines = []
        files_to_open_in_sublime = []
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
              content_at_filename,
              files_to_open_in_sublime
            )
          elsif 1 == number_of_exact_matches && :auto == strategy
            # There is exactly one perfect match, replace it automatically
            replace_perfect_match!(correction, corrected_at, report_lines)
          elsif :manual == strategy
            # Multiple matches
            pick_from_multiple_matches!(correction, corrected_at, report_lines)
          end
        }
        Outcome.new(true, corrected_at, report_lines)
      end

      # This method is called when no perfect matches can be found.
      # @param[Hash] correction
      # @param[String] corrected_at will be updated in place
      # @param[Array] report_lines collector for report output
      # @param[String] content_at_filename filename of the content_at file
      # @param[Array] files_to_open_in_sublime collector for files to be opened later
      def self.try_fuzzy_match!(correction, corrected_at, report_lines, content_at_filename, files_to_open_in_sublime)
        # Check if correction was already applied
        if 1 == corrected_at.scan(correction[:after]).size
          l = "##{ correction[:correction_number] }: It appears that this correction has already been applied. (Exact)"
          report_lines << l
          $stderr.puts l
          return
        end
        # Try fuzzy match: Remove gap_marks and subtitle_marks and see if that was applied already
        correction_after_without_marks = correction[:after].gsub(/[%@]/, '')
        corrected_at_without_marks = corrected_at.gsub(/[%@]/, '')
        if 1 == corrected_at_without_marks.scan(correction_after_without_marks).size
          l = "##{ correction[:correction_number] }: It appears that this correction has already been applied. (Except gap_mark or subtitle_mark)"
          report_lines << l
          $stderr.puts l
          return
        end

        # No match found, open location in sublime
        # Compute line number
        regex = /
          .*? # match anything nongreedily
          \n\*#{ correction[:paragraph_number] }\*\{\:\s\.pn\} # match paragraph number span
        /xm # multiline
        text_before_paragraph = corrected_at.match(regex).to_s
        subl_line = text_before_paragraph.count("\n") + 1
        l = "##{ correction[:correction_number] }: No exact match found, update manually."
        report_lines << l
        $stderr.puts l
        open_in_sublime(
          content_at_filename,
          [
            "    Could not find phrase '#{ correction[:before] }' in paragraph #{ correction[:paragraph_number] }",
            "    Replace with: '#{ correction[:after] }'",
          ].join("\n"),
          subl_line
        )
      end

      def self.replace_perfect_match!(correction, corrected_at, report_lines)
        corrected_at.gsub!(correction[:before], correction[:after])
        l = "##{ correction[:correction_number] }: Found exact match and updated automatically."
        report_lines << l
        $stderr.puts l
      end

      def self.pick_from_multiple_matches!(correction, corrected_at, report_lines)
        l = "##{ correction[:correction_number] }: Multiple matches found."
        report_lines << l
        $stderr.puts l
      end

      # Opens filename in sublime and places cursor at line and col
      def self.open_in_sublime(filename, console_instructions, line=nil, col=nil)
        location_spec = [filename, line, col].compact.map { |e| e.to_s.strip }.join(':')
        $stderr.puts console_instructions
        `subl --wait --new-window --command select_lines #{ location_spec }`
      end

    end
  end
end
