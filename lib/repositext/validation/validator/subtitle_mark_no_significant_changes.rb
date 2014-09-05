class Repositext
  class Validation
    class Validator
      # Validates that subtitle_marks have not changed significantly in content
      # AT file compared to the corresponding subtitle_markers csv file.
      class SubtitleMarkNoSignificantChanges < Validator

        # Runs all validations for self
        def run
          errors, warnings = [], []

          catch(:abandon) do
            content_at_filename, subtitle_marker_csv_filename = @file_to_validate

            outcome = significant_changes?(
              ::File.read(content_at_filename),
              ::File.read(subtitle_marker_csv_filename)
            )
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      private

        # Checks if any subtitle_marks have been changed significantly compared
        # to their positions saved in subtitle_markers.csv
        # @param[String] content_at
        # @param[CSV] subtitle_marker_csv
        # @return[Outcome]
        def significant_changes?(content_at, subtitle_marker_csv)
          raise "content_at is empty."  if content_at.to_s.strip.empty?
          raise "subtitle_marker_csv is empty."  if subtitle_marker_csv.to_s.strip.empty?
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
            if subtitle_mark_changed_significantly?(old_pos, old_len, new_pos, new_len)
              line_num = content_at[0..new_pos].count("\n") + 1
              significantly_changed_captions << { excerpt: new_caption[:excerpt], line_num: line_num }
            end
          }
          if significantly_changed_captions.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.first], # content_at file
                  [
                    'Subtitle_mark position has changed significantly',
                    significantly_changed_captions.map { |e|
                      "On line #{ e[:line_num] }: #{ e[:excerpt] }"
                    }.join("\n")
                  ]
                )
              ]
            )
          end
        end

        # Returns true if a subtitle_mark is considered to have changed significantly
        # @param[Integer] old_pos
        # @param[Integer] old_len
        # @param[Integer] new_pos
        # @param[Integer] new_len
        def subtitle_mark_changed_significantly?(old_pos, old_len, new_pos, new_len)
          relative_change = (new_pos - old_pos).abs / old_len.to_f
          threshold = case old_len
          when 0..24
            # If a caption size is 0-24 characters in length a position change
            # of +/- 30% is considered significant
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
