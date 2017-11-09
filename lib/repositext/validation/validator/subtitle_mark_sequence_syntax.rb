class Repositext
  class Validation
    class Validator
      # Validates that all subtitle mark sequences (two or more subtitle marks
      # in a row with no content) are valid.
      class SubtitleMarkSequenceSyntax < Validator

        class InvalidSubtitleMarkSequenceError < StandardError; end

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = subtitle_mark_sequences_valid?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that all subtitle mark sequences are valid
        def subtitle_mark_sequences_valid?(content_at_file)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content_at_file.contents.index('@')

          invalid_subtitle_mark_sequences = find_invalid_subtitle_mark_sequences(
            content_at_file.contents
          )
          if invalid_subtitle_mark_sequences.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              invalid_subtitle_mark_sequences.map { |(error, line, excerpt)|
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                    line: line,
                    context: excerpt,
                  },
                  [error]
                )
              }
            )
          end
        end

        def find_invalid_subtitle_mark_sequences(content)
          r = []
          # split on para boundaries for location info
          content.split(/\n/).each_with_index { |para, line_idx|
            if para =~ /@\s+@/
              # Space inside subtitle mark sequence.
              r << ["Space inside subtitle mark sequence:", line_idx + 1, para]
            elsif para =~ /@\s+$/
              # Space between subtitle mark and trailing eagle.
              r << ["Space between subtitle mark and trailing eagle:", line_idx + 1, para]
            end
          }
          r
        end

      end
    end
  end
end

