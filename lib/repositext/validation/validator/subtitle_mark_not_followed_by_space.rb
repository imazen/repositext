class Repositext
  class Validation
    class Validator
      # Validates that no subtitle_mark is followed by certain whitespace characters.
      # Example of invalid string: "word1@ word2"
      class SubtitleMarkNotFollowedBySpace < Validator

        class SubtitleMarkFollowedBySpaceError < StandardError; end

        # Runs all validations for self
        def run
          document_to_validate = @file_to_validate.read
          outcome = no_subtitle_marks_followed_by_space?(
            document_to_validate
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param content [String]
        # @return [Outcome]
        def no_subtitle_marks_followed_by_space?(content)
          # Early return if content doesn't contain any subtitle_marks
          return Outcome.new(true, nil)  if !content.index('@')

          # We raise an exception if we find any errors
          subtitle_marks_followed_by_space = find_subtitle_marks_followed_by_space(content)
          if subtitle_marks_followed_by_space.empty?
            Outcome.new(true, nil)
          else
            # We want to terminate an import if there is an issue.
            # Normally we'd return a negative outcome (see :content), but in this
            # case we raise an exception.
            raise NoSubtitleMarkAtBeginningOfParagraphError.new(
              [
                "The following subtitle_marks are followed by a space:",
                subtitle_marks_followed_by_space.map { |e| e.inspect }.join("\n")
              ].join("\n")
            )
          end
        end

        # @param content [String]
        # @return [Array]
        def find_subtitle_marks_followed_by_space(content)
          r = []
          # split on para boundaries for location info
          content.split(/\n/).each_with_index { |para, line_idx|
            # Find any subtitle marks followed by:
            # * regular space
            # * 00A0
            # * 202F
            if para =~ /@[\ \u00A0\u202F]/
              r << ["line #{ line_idx + 1}", para]
            end
          }
          r
        end

      end
    end
  end
end
