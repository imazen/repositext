class Repositext
  class Validation
    class Validator
      # Validates that all subtitle mark sequences (two or more subtitle marks
      # in a row with no content) are valid.
      class SubtitleMarkSequenceSyntax < Validator

        class InvalidSubtitleMarkSequenceError < StandardError; end

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          outcome = subtitle_mark_sequences_valid?(
            document_to_validate
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that all subtitle mark sequences are valid
        # @param content [String]
        # @return [Outcome]
        def subtitle_mark_sequences_valid?(content)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content.index('@')

          invalid_subtitle_mark_sequences = find_invalid_subtitle_mark_sequences(content)
          if invalid_subtitle_mark_sequences.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              invalid_subtitle_mark_sequences.map { |(error, line, excerpt)|
                Reportable.error(
                  [@file_to_validate.path, "line #{ line }"], # content_at file
                  [error, excerpt]
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
              r << ["Space inside subtitle mark sequence:", "line #{ line_idx + 1 }", para]
            elsif para =~ /@\s+$/
              # Space between subtitle mark and trailing eagle.
              r << ["Space between subtitle mark and trailing eagle:", "line #{ line_idx + 1 }", para]
            end
          }
          r
        end

      end
    end
  end
end

