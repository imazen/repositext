class Repositext
  class Merge
    class AcceptedCorrectionsIntoContentAt

      class InvalidAcceptedCorrectionsFile < StandardError; end
      class InvalidCorrectionAttributes < StandardError; end
      class InvalidCorrectionNumber < StandardError; end

      # Auto-merges accepted_corrections into content_at in unambiguous corrections
      # that can be applied automatically.
      # @param[String] accepted_corrections
      # @param[String] content_at to merge corrections into
      # @param[String] content_at_filename
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge_auto(accepted_corrections, content_at, content_at_filename)
        sanitized_corrections = sanitize_line_breaks(accepted_corrections)
        validate_accepted_corrections_file(sanitized_corrections)
        corrections = extract_corrections(sanitized_corrections)
        validate_corrections(corrections)
        outcome = merge_corrections_into_content_at(:auto, corrections, content_at, content_at_filename)
      end

      # Manually merges accepted_corrections into content_at in corrections that
      # require human review and decision. Opens files in a text editor.
      # @param[String] accepted_corrections
      # @param[String] content_at to merge corrections into
      # @param[String] content_at_filename
      # @return[Outcome] the merged document is returned as #result if successful.
      def self.merge_manually(accepted_corrections, content_at, content_at_filename)
        sanitized_corrections = sanitize_line_breaks(accepted_corrections)
        corrections = extract_corrections(sanitized_corrections)
        validate_corrections(corrections)
        outcome = merge_corrections_into_content_at(:manual, corrections, content_at, content_at_filename)
      end

    protected

      # Replaces all \r with \n
      def self.sanitize_line_breaks(txt)
        txt.gsub("\r", "\n")
      end

      # Validates the contents of the accepted_corrections file before it attempts
      # any parsing.
      # @param[String] accepted_corrections
      def self.validate_accepted_corrections_file(accepted_corrections)
        # Validate that no invalid characters are in correction file
        # NOTE: straight double quotes are allowed inside kramdown IALs, so we
        # convert them to a placeholder string ('<sdq>') for validation purposes.
        txt = accepted_corrections.gsub(/(?<=\{)[^\{\}]*(?=\})/) { |inside_ial|
          inside_ial.gsub(/"/, '<sdq>')
        }

        invalid_chars = []
        [
          [/–/, 'EN DASH'],
          [/"/, 'Straight double quote'],
          [/'/, 'Straight single quote'],
          [/\r/, 'Carriage return'],
        ].each do |(regex, description)|
          s = StringScanner.new(txt)
          while !s.eos? do
            inv_char = s.scan_until(/.{,5}#{ regex }/) # match up to 5 chars before invalid char for reporting context
            if inv_char
              previous_text = txt[0..(s.pos - 1)]
              line_num = previous_text.count("\n") + 1
              context = s.matched[(-[10, s.matched.length].min)..-1] + s.rest[0,10]
              invalid_chars << " - #{ description } on line #{ line_num }: #{ context.inspect }"
            else
              s.terminate
            end
          end
        end
        if invalid_chars.any?
          msg = ["Invalid characters:"]
          msg += invalid_chars
          raise InvalidAcceptedCorrectionsFile.new(msg.join("\n"))
        end
      end

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
            if (match = correction_location.match(/lines?\s+([\d\-]+)/i))
              ca[:line_number] = match[1].to_s
            else
              raise "Could not parse line number for correction ##{ ca[:correction_number] }, para ##{ ca[:paragraph_number] }"
            end
            # extract reads
            s.skip_until(/\nreads:\s+/i) # advance up to and including reads: marker
            ca[:before] = s.scan(/.+?(?=\nbecomes:)/im).to_s.strip # fetch everything up to "Becomes:"
            # extract becomes
            s.skip_until(/\nbecomes:\s+/i) # advance up to and including becomes: marker
            ca[:after] = s.scan(/.+?(?=(\n{2,}\d+\.|\s+\z))/m).to_s.strip # fetch up to next correction number, or end of document
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
          raise InvalidCorrectionAttributes.new("Not all attrs are present: #{ with_missing_attrs.inspect }")
        end

        # Validate that we get consecutive correction_numbers
        correction_numbers = corrections.map { |e| e[:correction_number].to_i }.sort
        correction_numbers.each_cons(2) { |x,y|
          if y != x + 1
            raise InvalidCorrectionNumber.new("Correction numbers are not consecutive: #{ [x,y].inspect }")
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
          relevant_paragraphs = extract_relevant_paragraphs(corrected_at, correction)
          merge_action, specifier = compute_merge_action(strategy, correction, relevant_paragraphs)
          case merge_action
          when :apply_automatically
            replace_perfect_match!(correction, corrected_at, relevant_paragraphs, report_lines)
          when :report_already_applied
            report_correction_has_already_been_applied(correction, specifier, report_lines)
          when :apply_manually
            manually_edit_correction!(
              correction,
              corrected_at,
              report_lines,
              content_at_filename,
              specifier
            )
          when :do_nothing
            # do exactly that
          else
            raise "Invalid action: #{ action.inspect }"
          end
        }
        Outcome.new(true, corrected_at, report_lines)
      end

      # Looks at various matches and returns an action to take
      # @param[Symbol] strategy one of :auto, :manual
      # @param[Hash] correction
      # @param[String] relevant_paragraphs
      # @return[Array] with the merge action and an optional specifier
      def self.compute_merge_action(strategy, correction, relevant_paragraphs)
        # count the various matches
        exact_before_matches_count = relevant_paragraphs.scan(correction[:before]).length
        exact_after_matches_count = relevant_paragraphs.scan(correction[:after]).length
        fuzzy_after_matches_count = compute_fuzzy_after_matches_count(correction, relevant_paragraphs)
        # First decision criterion must be strategy since we have to keep automated
        # changes separate from manual ones (one operates on string in memory,
        # the other operates on string in files).
        case strategy
        when :auto
          if (
            1 == exact_before_matches_count &&
            0 == exact_after_matches_count &&
            0 == fuzzy_after_matches_count
          )
            # There is exactly one perfect 'before' match, and no 'after' matches.
            # That means we haven't applied the correction already and can
            # apply it automatically.
            [:apply_automatically]
          else
            # Nothing to do, can't handle any other cases automatically.
            [:do_nothing]
          end
        when :manual
          if (0 == exact_before_matches_count)
            # No exact :before matches found
            if 1 == exact_after_matches_count
              [:report_already_applied, 'Exact']
            elsif 1 == fuzzy_after_matches_count
              [:report_already_applied, '~Fuzzy']
            else
              # Either none or multiple :after matches
              [:apply_manually, :no_match_found]
            end
          else
            # Multiple exact :before matches found
            [:apply_manually, :multiple_matches_found]
          end
        else
          raise "Invalid strategy: #{ strategy.inspect }"
        end
      end

      # Reports that a correction has already been applied
      # @param[Hash] correction
      # @param[String] precision, e.g., 'Exact' or 'Fuzzy'
      # @param[Array] report_lines collector for report output
      def self.report_correction_has_already_been_applied(correction, precision, report_lines)
        l = "    ##{ correction[:correction_number] }: It appears that this correction has already been applied. (#{ precision })"
        report_lines << l
        $stderr.puts l
      end

      # Returns the number of fuzzy :after matches in txt
      # @param[Hash] correction
      # @param[String] txt the text in relevant_paragraphs
      # @return[Integer]
      def self.compute_fuzzy_after_matches_count(correction, txt)
        # Try fuzzy match: Remove gap_marks and subtitle_marks and see if that was applied already
        fuzzy_correction_after = correction[:after].gsub(/[%@]/, '')
        fuzzy_txt = txt.gsub(/[%@]/, '')
        fuzzy_txt.scan(fuzzy_correction_after).size
      end

      # This method is called when correction cannot be applied automatically.
      # @param[Hash] correction
      # @param[String] corrected_at will be updated in place
      # @param[Array] report_lines collector for report output
      # @param[String] content_at_filename filename of the content_at file
      # @param[Symbol] reason one of :no_match_found, or :multiple_matches_found
      def self.manually_edit_correction!(correction, corrected_at, report_lines, content_at_filename, reason)
        log_line, instructions = case reason
        when :no_match_found
          [
            "    ##{ correction[:correction_number] }: No match found, apply correction manually:",
            "      Could not find exact phrase        '#{ correction[:before] }'",
          ]
        when :multiple_matches_found
          [
            "    ##{ correction[:correction_number] }: Multiple matches found, apply correction manually:",
            "      Found multiple instances of phrase '#{ correction[:before] }'",
          ]
        else
          raise "Invalid reason: #{ reason.inspect }"
        end
        # Open location in sublime
        report_lines << log_line
        $stderr.puts log_line
        open_in_sublime(
          content_at_filename,
          [
            instructions,
            "      Replace with:                      '#{ correction[:after] }'",
            "      in paragraph #{ correction[:paragraph_number] }, line #{ correction[:line_number] }",
          ].join("\n"),
          compute_line_number_from_paragraph_number(correction[:paragraph_number], corrected_at)
        )
      end

      # Automatically applies correction because we have confidence
      # @param[Hash] correction
      # @param[String] corrected_at will be updated in place
      # @param[String] relevant_paragraphs
      # @param[Array] report_lines collector for report output
      def self.replace_perfect_match!(correction, corrected_at, relevant_paragraphs, report_lines)
        # First apply correction to relevant paragraphs
        corrected_relevant_paragraphs = relevant_paragraphs.gsub(correction[:before], correction[:after])
        # Then apply corrected_relevant_paragraphs to corrected_at
        exact_matches_count = corrected_at.scan(relevant_paragraphs).size
        if 1 == exact_matches_count
          corrected_at.gsub!(relevant_paragraphs, corrected_relevant_paragraphs)
          l = "    ##{ correction[:correction_number] }: Found exact match and updated automatically."
          report_lines << l
          $stderr.puts l
        elsif 0 == exact_matches_count
          raise "Could not locate #{ relevant_paragraphs.inspect } in corrected_at"
        else
          raise "Found multiple instances of #{ relevant_paragraphs.inspect } in corrected_at"
        end
      end

      # Given txt and paragraph_number, returns the line at which paragraph_number starts
      # @param[Integer, String] paragraph_number
      # @param[String] txt
      # @return[Integer] the line number (1-based)
      def self.compute_line_number_from_paragraph_number(paragraph_number, txt)
        regex = /
          .*? # match anything non greedily
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
          # First paragraph doesn't have a number, match beginning of document
          /\A/
        else
          /\n[@%]{0,2}\*#{ paragraph_number.to_s.strip }\*\{\:\s\.pn\}/
        end
      end

      # Returns the number of the first paragraph. Normally '1', however there
      # are exceptions.
      # @param[String] txt
      # @return[String] the first paragraph number as string
      def self.compute_first_para_num(txt)
        fpn = (txt.match(/\n[@%]{0,2}\*(\d+)\*\{\:\s\.pn\}/)[1].to_s.to_i - 1).to_s
        fpn = '1'  if '0' == fpn # in case first para has a number
        fpn
      end

      # Extracts relevant paragraphs from txt, based on paragraph_number
      # @param[String] txt the complete text to extract relevant paragraphs from
      # @param[Hash] correction attrs for a single correction
      # @return[String] the text of the relevant paragraphs
      def self.extract_relevant_paragraphs(txt, correction)
        # Check if correction was already applied to the relevant paragraph
        # Extract relevant paragraph
        or_match_on_eagle = if compute_first_para_num(txt) == correction[:paragraph_number].to_s
          # Don't stop at eagle when looking for paragraph 1, because it would stop at the starting eagle
          ''
        else
          # Stop also at eagle in case we're looking at the last paragraph that doesn't have a subsequent one
          '|'
        end
        # Capture more than a single paragraph for corrections that span paragraph boundaries
        how_many_paras_to_match = (correction[:after].scan('*{: .pn}').size) + 1
        stop_para_number = how_many_paras_to_match.times.each.inject(
          correction[:paragraph_number]
        ) { |m,e| m.succ }
        relevant_paragraphs = txt.match(
          /
            #{ dynamic_paragraph_number_regex(correction[:paragraph_number], txt) } # match paragraph number span
            .*? # match anything nongreedily
            (?=(
              #{ dynamic_paragraph_number_regex(stop_para_number, txt) } # stop before next paragraph number
              #{ or_match_on_eagle }
            ))
          /xm # multiline
        ).to_s
        if '' == relevant_paragraphs
          raise "Could not find paragraph #{ correction[:paragraph_number] }"
        end
        relevant_paragraphs
      end

    end
  end
end
