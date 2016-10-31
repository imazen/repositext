class Repositext
  class Process
    class Merge

      # Merges spot corrections from a spot sheet into content AT.
      # It does so in two steps:
      #
      # 1. Repositext applies all corrections that can be done automatically
      #    (based on exact text matches).
      # 2. A human editor applies manual corrections where no or multiple exact
      #    matches are found. The script opens each file in an editor to speed up
      #    the manual task.
      #
      # We have to do it in two steps so that when we open the file in the editor
      # for manual changes, all auto corrections are already applied to the file
      # and they don't overwrite any manual corrections prior to when the script
      # stores auto corrections to disk.
      #
      # ### Process
      #
      # The calling method loads the spots file and the existing content AT file and
      # passes both to the `.merge_auto` method. This method merges all corrections that
      # can be applied automatically into content AT and returns the modified content AT.
      #
      # The calling method then passes the original corrections and the modified
      # content AT to `.merge_manually`. This method finds any manual corrections and
      # opens each affected location in the user's configured text editor. The human
      # editor can apply the correction and save it manually.
      #
      # Each of the two stages calls `.merge_corrections_into_content_at` with the
      # desired strategy (:auto or :manual). This method keeps track of the corrected
      # content AT. Then it iterates over all corrections and takes suitable action. It
      # returns the corrected content AT. It calls `.compute_merge_action` to
      # determine what needs to be done:
      #
      # `.compute_merge_action` is the rules engine that decides what to do with
      # each correction. It computes three counts of matches to decide on a
      # strategy:
      #
      # * `exact_before_matches_count`: How many times does `correction[:reads]`
      #   match exactly with current content_at's relevant paragraphs.
      # * `.exact_after_matches_count`: How many times does `correction[:becomes]`
      #   match exactly with current content_at's relevant paragraphs.
      # * `.fuzzy_after_matches_count`: How many times does `correction[:becomes]`
      #   match with content at's relevant paragraphs after all gap_marks and
      #   subtitle_marks have been removed from both.
      #
      # For each correction it returns the most appropriate merge action:
      #
      # * `:apply_automatically` - The correction can be applied automatically to
      #   content AT if all of the following conditions are met:
      #     * exact_before_matches_count = 1
      #     * exact_after_matches_count = 0
      #     * fuzzy_after_matches_count = 0
      # * `:report_already_applied` - The correction will be reported as already
      #   having been applied if all of the following conditions are met:
      #     * exact_before_matches_count = 0
      #     * exact_after_matches_count = 1 (Exact) or fuzzy_after_matches_count = 1 (~Fuzzy)
      # * `:apply_manually` - In the `:manual` strategy, this will open the text
      #   editor in the correct location if conditions for `:report_already_applied`
      #   are not being met.
      #
      class AcceptedCorrectionsIntoContentAt

        # Auto-merges accepted_corrections into content_at in unambiguous corrections
        # that can be applied automatically.
        # @param accepted_corrections [String]
        # @param content_at [String] to merge corrections into
        # @param content_at_filename [String]
        # @return [Outcome] the merged document is returned as #result if successful.
        def self.merge_auto(accepted_corrections, content_at, content_at_filename)
          corrections = extract_corrections(accepted_corrections)
          outcome = merge_corrections_into_content_at(:auto, corrections, content_at, content_at_filename)
        end

        # Manually merges accepted_corrections into content_at in corrections that
        # require human review and decision. Opens files in a text editor.
        # @param accepted_corrections [String]
        # @param content_at [String]  to merge corrections into
        # @param content_at_filename [String]
        # @return [Outcome] the merged document is returned as #result if successful.
        def self.merge_manually(accepted_corrections, content_at, content_at_filename)
          corrections = extract_corrections(accepted_corrections)
          outcome = merge_corrections_into_content_at(:manual, corrections, content_at, content_at_filename)
        end

      protected

        # @param [String] accepted_corrections
        # @return [Array<Hash>] a hash describing the corrections
        def self.extract_corrections(accepted_corrections)
          Repositext::Process::Extract::SubmittedSpotCorrections.extract(accepted_corrections)
        end

        # Merges corrections into content_at
        # @param [Symbol] strategy one of :auto, :manual
        # @param [Array<Hash>] corrections
        # @param [String] content_at
        # @param [String] content_at_filename
        # @return [Outcome] where result is corrected_at and messages contains the report_lines
        def self.merge_corrections_into_content_at(strategy, corrections, content_at, content_at_filename)
          report_lines = []
          corrected_at = content_at.dup

          corrections.each { |correction|
            relevant_paragraphs_attrs = Process::Extract::SpotCorrectionRelevantParagraphs.extract(
              correction,
              corrected_at
            )
            relevant_paragraphs = relevant_paragraphs_attrs[:relevant_paragraphs]
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
                specifier,
                relevant_paragraphs_attrs[:paragraph_start_line_number]
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
        # @param [Symbol] strategy one of :auto, :manual
        # @param [Hash] correction
        # @param [String] relevant_paragraphs
        # @return [Array] with the merge action and an optional specifier
        def self.compute_merge_action(strategy, correction, relevant_paragraphs)
          return [:do_nothing]  if correction[:no_change]

          # count the various matches
          exact_before_matches_count = relevant_paragraphs.scan(correction[:reads]).length
          exact_after_matches_count = relevant_paragraphs.scan(correction[:becomes]).length
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
              # No exact :reads matches found
              if 1 == exact_after_matches_count
                [:report_already_applied, 'Exact']
              elsif 1 == fuzzy_after_matches_count
                [:report_already_applied, '~Fuzzy (ignoring gap_marks and subtitle_marks)']
              else
                # Either none or multiple :becomes matches
                [:apply_manually, :no_match_found]
              end
            else
              # Multiple exact :reads matches found
              [:apply_manually, :multiple_matches_found]
            end
          else
            raise "Invalid strategy: #{ strategy.inspect }"
          end
        end

        # Reports that a correction has already been applied
        # @param correction [Hash]
        # @param precision [String] e.g., 'Exact' or 'Fuzzy'
        # @param report_lines [Array] collector for report output
        def self.report_correction_has_already_been_applied(correction, precision, report_lines)
          l = "    ##{ correction[:correction_number] }: It appears that this correction has already been applied. (#{ precision })"
          report_lines << l
          $stderr.puts l
        end

        # Returns the number of fuzzy :becomes matches in txt
        # @param [Hash] correction
        # @param [String] txt the text in relevant_paragraphs
        # @return [Integer]
        def self.compute_fuzzy_after_matches_count(correction, txt)
          # Try fuzzy match: Remove gap_marks and subtitle_marks and see if that was applied already
          fuzzy_correction_after = correction[:becomes].gsub(/[%@]/, '')
          fuzzy_txt = txt.gsub(/[%@]/, '')
          fuzzy_txt.scan(fuzzy_correction_after).size
        end

        # This method is called when correction cannot be applied automatically.
        # @param correction [Hash]
        # @param corrected_at [String] will be updated in place
        # @param report_lines [Array] collector for report output
        # @param content_at_filename [String] filename of the content_at file
        # @param reason [Symbol] one of :no_match_found, or :multiple_matches_found
        # @param paragraph_start_line_number [Integer]
        def self.manually_edit_correction!(correction, corrected_at, report_lines, content_at_filename, reason, paragraph_start_line_number)
          log_line, instructions = case reason
          when :no_match_found
            [
              "    ##{ correction[:correction_number] }: No match found, apply correction manually:",
              "      Could not find exact phrase        '#{ correction[:reads] }'",
            ]
          when :multiple_matches_found
            [
              "    ##{ correction[:correction_number] }: Multiple matches found, apply correction manually:",
              "      Found multiple instances of phrase '#{ correction[:reads] }'",
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
              "      Replace with:                      '#{ correction[:becomes] }'",
              "      in paragraph #{ correction[:paragraph_number] }",
            ].join("\n"),
            paragraph_start_line_number
          )
        end

        # Automatically applies correction because we have confidence
        # @param [Hash] correction
        # @param [String] corrected_at will be updated in place
        # @param [String] relevant_paragraphs
        # @param [Array] report_lines collector for report output
        def self.replace_perfect_match!(correction, corrected_at, relevant_paragraphs, report_lines)
          # First apply correction to relevant paragraphs
          corrected_relevant_paragraphs = relevant_paragraphs.gsub(correction[:reads], correction[:becomes])
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

        # Opens filename in sublime and places cursor at line and col
        def self.open_in_sublime(filename, console_instructions, line=nil, col=nil)
          location_spec = [filename, line, col].compact.map { |e| e.to_s.strip }.join(':')
          $stderr.puts console_instructions
          `subl --wait --new-window #{ location_spec }`
        end

      end
    end
  end
end
