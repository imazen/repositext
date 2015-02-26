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
        # to their positions saved in subtitle_markers.csv
        # Only applied if content_at contains subtitle_marks.
        # @param[String] content_at
        # @param[CSV String] subtitle_marker_csv
        # @return[Outcome]
        def significant_changes?(content_at, subtitle_marker_csv)
          raise(ArgumentError.new("content_at is empty."))  if content_at.to_s.strip.empty?
          raise(ArgumentError.new("subtitle_marker_csv is empty."))  if subtitle_marker_csv.to_s.strip.empty?
          if !content_at.index('@')
            # Document doesn't contain subtitle marks, skip it
            return Outcome.new(true, nil)
          end
          csv = CSV.new(subtitle_marker_csv, col_sep: "\t", headers: :first_row)
          previous_stm_positions_and_lengths = csv.to_a.map { |row|
            r = row.to_hash
            { char_pos: r['charPos'].to_i, char_length: r['charLength'].to_i }
          }
          new_captions = Repositext::Utils::SubtitleMarkTools.extract_captions(content_at)
          # make sure that both counts are identical
          if new_captions.length != previous_stm_positions_and_lengths.length
            # TODO: maybe we have to make them the same length, if stm was added or removed
            raise "Different counts: #{ previous_stm_positions_and_lengths.length } -> #{ new_captions.length }"
          end

          significantly_changed_captions = []
          previous_stm_positions_and_lengths.each_with_index { |old_caption, idx|
            new_caption = new_captions[idx]
            old_pos = old_caption[:char_pos]
            old_len = old_caption[:char_length]
            new_pos = new_caption[:char_pos]
            new_len = new_caption[:char_length]
            if subtitle_mark_changed_significantly?(old_len, new_len)
              line_num = content_at[0..new_pos].count("\n") + 1
              significantly_changed_captions << {
                excerpt: new_caption[:excerpt],
                line_num: line_num,
                subtitle_index: idx
              }
            end
          }
          if significantly_changed_captions.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.first.path], # content_at file
                  [
                    'Subtitle caption length has changed significantly',
                    'Review changes and update subtitle_markers_file with `repositext sync subtitle_mark_character_positions`',
                    significantly_changed_captions.map { |e|
                      "Subtitle index #{ e[:subtitle_index] } on line #{ e[:line_num] }: #{ e[:excerpt] }"
                    }.join("\n")
                  ]
                )
              ]
            )
          end
        end

        # Returns true if a subtitle_mark's caption length has changed significantly
        # @param[Integer] old_len
        # @param[Integer] new_len
        def subtitle_mark_changed_significantly?(old_len, new_len)
          relative_change = (new_len - old_len).abs / old_len.to_f
          threshold = case old_len
          when 0..24
            # If a caption is 0-24 characters long, a length change of
            # +/- 30% is considered significant
            0.3
          when 25..60
            0.25
          when 61..120
            0.2
          else
            raise "Found subtitle_mark spacing > 120 (#{ old_len })."
          end
          relative_change >= threshold
        end

      end
    end
  end
end
