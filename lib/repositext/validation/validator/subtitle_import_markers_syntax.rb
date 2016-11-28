class Repositext
  class Validation
    class Validator
      # Validates syntax of subtitle markers import file.
      class SubtitleImportMarkersSyntax < Validator

        class UnexpectedSpaceError < ::StandardError; end

        # Runs all validations for self
        def run
          # @file_to_validate is the import markers file.
          subtitle_import_markers_file = @file_to_validate
          outcome = no_unexpected_spaces?(subtitle_import_markers_file.read)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if markers file contains any spaces. It shouldn't. Only tabs!
        # @param markers_contents [String]
        # @return [Outcome]
        def no_unexpected_spaces?(markers_contents)
          spaces_count = markers_contents.count(' ')
          if 0 == spaces_count
            Outcome.new(true, nil)
          else
            # We want to terminate an import if markers file contains spaces.
            # Normally we'd return a negative outcome, but in this case we raise
            # an exception.
            raise UnexpectedSpaceError.new(
              [
                "\n\nUnexpected space characters in subtitle/subtitle_tagging_import markers file #{ @file_to_validate.path }.",
                "Cannot proceed with import. Please replace spaces in markers file with tabs.",
              ].join("\n")
            )
          end
        end

      end
    end
  end
end
