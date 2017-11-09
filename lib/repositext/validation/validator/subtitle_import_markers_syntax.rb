class Repositext
  class Validation
    class Validator
      # Validates syntax of subtitle markers import file.
      class SubtitleImportMarkersSyntax < Validator

        class UnexpectedSpaceError < ::StandardError; end

        # Runs all validations for self
        def run
          subtitle_import_markers_file = @file_to_validate
          outcome = no_unexpected_spaces?(subtitle_import_markers_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if markers file contains any spaces. It shouldn't. Only tabs!
        # @param subtitle_import_markers_file [RFile::SubtitleMarkerCsv]
        # @return [Outcome]
        def no_unexpected_spaces?(subtitle_import_markers_file)
          spaces_count = subtitle_import_markers_file.contents.count(' ')
          if 0 == spaces_count
            Outcome.new(true, nil)
          else
            # We want to terminate an import if markers file contains spaces.
            # Normally we'd return a negative outcome, but in this case we raise
            # an exception.
            raise UnexpectedSpaceError.new(
              [
                "\n\nUnexpected space characters in subtitle/subtitle_tagging_import markers file #{ subtitle_import_markers_file.filename }.",
                "Cannot proceed with import. Please replace spaces in markers file with tabs.",
              ].join("\n")
            )
          end
        end

      end
    end
  end
end
