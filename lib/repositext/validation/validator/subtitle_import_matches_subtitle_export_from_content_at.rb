class Repositext
  class Validation
    class Validator
      # Validates that the subtitle/subtitle_tagging import file is identical
      # to the subtitle export generated from the new content AT (with updated
      # subtitle_marks). This is a safety net to make sure nothing went wrong.
      class SubtitleImportMatchesSubtitleExportFromContentAt < Validator

        # Runs all validations for self
        def run
          errors, warnings = [], []

          catch(:abandon) do
            # @file_to_validate is an array with the paths to the content_at and
            # subtitle/subtitle_tagging_import files
            content_at_filename, subtitle_import_filename = @file_to_validate
            outcome = contents_match?(
              ::File.read(content_at_filename),
              ::File.read(subtitle_import_filename)
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

        # Checks if subtitle/subtitle_tagging import text and subtitle_export from content_at match.
        # Unlike Repositext::Validation::Validator::SubtitleImportConsistency,
        # we leave subtitle_marks in place since they should be consistent.
        # (We use content AT after subtitle_marks have been merged in).
        # @param[String] content_at
        # @param[String] subtitle_import
        # @return[Outcome]
        def contents_match?(content_at, subtitle_import)
          # We re-export content_at to subtitle and compare the result
          # with subtitle_import
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = @options['kramdown_parser_class'].parse(content_at)
          doc = Kramdown::Document.new('')
          doc.root = root
          tmp_subtitle_export = doc.send(@options['subtitle_converter_method_name'])
          diffs = Repositext::Utils::StringComparer.compare(
            subtitle_import, #.gsub(/[%@]/, ''),
            tmp_subtitle_export #.gsub(/[%@]/, '')
          )

          if diffs.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.last], # subtitle/subtitle_tagging_import file
                  [
                    'Text mismatch between subtitle/subtitle_tagging_import and subtitle_export from content_at:',
                    diffs.inspect
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
