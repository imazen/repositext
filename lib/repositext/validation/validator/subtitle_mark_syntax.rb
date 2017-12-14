class Repositext
  class Validation
    class Validator
      # Validates that all subtitle marks are valid.
      class SubtitleMarkSyntax < Validator

        class InvalidSubtitleMarkError < StandardError; end

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = subtitle_marks_valid?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that all subtitle marks are valid
        def subtitle_marks_valid?(content_at_file)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content_at_file.contents.index('@')

          invalid_subtitle_marks = find_invalid_subtitle_marks(
            content_at_file.contents
          )
          if invalid_subtitle_marks.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              invalid_subtitle_marks.map { |(error, line, excerpt)|
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

        def find_invalid_subtitle_marks(content)
          r = []
          # split on para boundaries for location info
          content.split(/\n\n/).each_with_index { |para, line_idx|
            if para =~ /\{[^\}]*@[^\}]*\}/
              r << ["Subtitle mark inside IAL:", line_idx + 1, para]
            end
            if para =~ /\([^\)]*@[^\)]*\)/
              r << ["Subtitle mark inside parenthesis:", line_idx + 1, para]
            end
          }
          r
        end

      end
    end
  end
end

