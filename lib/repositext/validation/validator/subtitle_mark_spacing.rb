class Repositext
  class Validation
    class Validator
      # Validates that there are 120 or less characters in each caption.
      # A caption is the segment of text between subtitle marks.
      # Include whitespace in this count excpet for leading or trailing.
      class SubtitleMarkSpacing < Validator

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          # @file_to_validate is an array with the paths to the content_at and subtitle_tagging_export files
          outcome = subtitle_marks_spaced_correctly?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks that subtitle marks in content_at are spaced correctly.
        # Only applied if content_at contains subtitle_marks.
        # @param[String] content_at
        # @return[Outcome]
        def subtitle_marks_spaced_correctly?(content_at)
          content_with_subtitle_marks_only = Repositext::Utils::SubtitleMarkTools.extract_body_text_with_subtitle_marks_only(content_at)
          if !content_with_subtitle_marks_only.index('@')
            # Document doesn't contain subtitle marks, skip it
            return Outcome.new(true, nil)
          end

          captions = Repositext::Utils::SubtitleMarkTools.extract_captions(
            content_with_subtitle_marks_only,
            true
          )
          too_long_captions = captions.find_all { |caption| caption[:char_length] > 120 }
          if too_long_captions.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.path], # content_at file
                  [
                    'The following captions are too long:',
                    too_long_captions.map { |e|
                      "#{ e.length } chars: #{ e.inspect }"
                    }.join("\n")
                  ]
                )
              ]
            )
          end
        end

      end
    end
  end
end
