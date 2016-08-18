class Repositext
  class Validation
    class Validator
      # Validates that subtitle_marks have not changed significantly in content
      # AT file compared to the corresponding subtitle_markers csv file.
      class SubtitleMarkNoSignificantChanges < Validator

        # Runs all validations for self
        def run
          content_at_filename, subtitle_marker_csv_filename = @file_to_validate
          outcome = significant_changes?(
            content_at_filename.read,
            subtitle_marker_csv_filename.read
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if any subtitle_marks have been changed significantly compared
        # to their lengths saved in subtitle_markers.csv
        # Only applied if content_at contains subtitle_marks.
        # @param [String] content_at
        # @param [CSV String] subtitle_marker_csv
        # @return [Outcome]
        def significant_changes?(content_at, subtitle_marker_csv)
          raise(ArgumentError.new("content_at is empty."))  if content_at.to_s.strip.empty?
          raise(ArgumentError.new("subtitle_marker_csv is empty."))  if subtitle_marker_csv.to_s.strip.empty?
          if !content_at.index('@')
            # Document doesn't contain subtitle marks, skip it
            return Outcome.new(true, nil)
          end
          csv = CSV.new(subtitle_marker_csv, col_sep: "\t", headers: :first_row)
          previous_stm_lengths = csv.to_a.map { |row|
            r = row.to_hash
            { char_length: r['charLength'].to_i }
          }
          new_captions = Repositext::Utils::SubtitleMarkTools.extract_captions(content_at)
          # make sure that both counts are identical
          if new_captions.length != previous_stm_lengths.length
            # There is a mismatch in subtitle_mark counts between CSV file and
            # content_at. It makes no sense to run this validator unless the
            # counts match. We just skip it silently.
            return Outcome.new(true, nil)
          end

          changed_captions = []
          previous_stm_lengths.each_with_index { |old_caption, idx|
            new_caption = new_captions[idx]
            old_len = old_caption[:char_length]
            new_len = new_caption[:char_length]
            change_severity = compute_subtitle_mark_change(old_len, new_len)
            if change_severity
              changed_captions << {
                severity: change_severity,
                excerpt: new_caption[:excerpt],
                line_num: new_caption[:line],
                subtitle_index: idx + 1 # subtitle_index is '1'-based in the other workflow tools
              }
            end
          }
          if changed_captions.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              changed_captions.map { |e|
                case e[:severity]
                when :insignificant
                  Reportable.warning(
                    [@file_to_validate.first.path], # content_at file
                    [
                      'Subtitle caption length has changed insignificantly',
                      "Subtitle ##{ e[:subtitle_index] } on line #{ e[:line_num] }: #{ e[:excerpt] }"
                    ]
                  )
                when :significant
                  Reportable.error(
                    [@file_to_validate.first.path], # content_at file
                    [
                      'Subtitle caption length has changed significantly',
                      'Review changes and update subtitle_markers_file with `repositext sync subtitle_mark_character_positions`',
                      "Subtitle ##{ e[:subtitle_index] } on line #{ e[:line_num] }: #{ e[:excerpt] }"
                    ]
                  )
                when :too_long
                  Reportable.error(
                    [@file_to_validate.first.path], # content_at file
                    [
                      'Subtitle caption is too long!',
                      "Subtitle ##{ e[:subtitle_index] } on line #{ e[:line_num] }: #{ e[:excerpt] }"
                    ]
                  )
                else
                  raise "Invalid severity: #{ e.inspect }"
                end
              }
            )
          end
        end

        # Returns :insignificant or :significant if a subtitle_mark's caption length has changed
        # @param [Integer] old_len
        # @param [Integer] new_len
        def compute_subtitle_mark_change(old_len, new_len)
          return :too_long  if new_len > 120
          relative_change = (new_len - old_len).abs / old_len.to_f
          threshold = case old_len
          when 0..24
            # If a caption is 0-24 characters long, a length change of
            # +/- 30% is considered significant
            0.3
          when 25..60
            0.25
          when else
            # longer then 60, possibly over 120
            0.2
          end
          if 0 == relative_change
            nil
          elsif relative_change < threshold
            :insignificant
          elsif relative_change >= threshold
            :significant
          else
            raise "Handle this: #{ relative_change.inspect }"
          end
        end

      end
    end
  end
end
