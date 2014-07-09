class Repositext
  class Validation
    class Validator
      # Validates that there are 120 or less characters in each caption.
      # A caption is the segment of text between subtitle marks.
      # Include whitespace in this count excpet for leading or trailing.
      class SubtitleMarkSpacing < Validator

        # Runs all validations for self
        def run
          errors, warnings = [], []

          catch (:abandon)  do
            # @file_to_validate is an array with the paths to the content_at and subtitle_tagging_export files
            outcome = subtitle_marks_spaced_correctly?(
              ::File.read(@file_to_validate)
            )

            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      end

    private

      # Checks that subtitle marks in content_at are spaced correctly
      # @param[String] content_at
      # @return[Outcome]
      def subtitle_marks_spaced_correctly?(content_at)
        content = content_at.dup
        # Remove title
        content.gsub!(/^#[^\n]+\n/, '')
        # Remove id title and paragraph
        content.gsub!(
          /
            [^\n]+\n # the line before a line that contains '.id_title1'
            [^\n]+\.id_title1 # line that contains id_title
            .* # anything after the line that contains .id_title
          /mx, # multiline so that the last .* matches multiple lines to the end of file
          ''
        )

        # Remove all tokens but :subtitle_mark from content_at
        content_with_subtitle_marks_only = Suspension::TokenRemover.new(
          content,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :subtitle_mark != e.name }
        ).remove

        captions = content_with_subtitle_marks_only.split('@')
        too_long_captions = captions.find_all { |caption|
          caption.strip.length > 120
        }
        if too_long_captions.empty?
          Outcome.new(true, nil)
        else
          Outcome.new(
            false, nil, [],
            [
              Reportable.error(
                [@file_to_validate], # content_at file
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
