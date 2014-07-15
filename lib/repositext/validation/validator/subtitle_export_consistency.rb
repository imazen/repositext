class Repositext
  class Validation
    class Validator
      # Validates that the subtitle/subtitle_tagging export still matches content_at
      class SubtitleExportConsistency < Validator

        # Runs all validations for self
        def run
          errors, warnings = [], []

          catch (:abandon)  do
            # @file_to_validate is an array with the paths to the content_at and subtitle_tagging_export files
            content_at_filename, subtitle_export_filename = @file_to_validate
            outcome = contents_match?(
              ::File.read(content_at_filename),
              ::File.read(subtitle_export_filename)
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

      # Checks if content_at and subtitle/subtitle_tagging export text contents match.
      # Removes subtitle_marks and gap_marks before comparison because those
      # are expected to change.
      # @param[String] content_at
      # @param[String] subtitle_export
      # @return[Outcome]
      def contents_match?(content_at, subtitle_export)
        # We re-export content_at to subtitle/subtitle_tagging and compare the result
        # with subtitle_export.
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
          subtitle_export.gsub(/[%@]/, ''),
          tmp_subtitle_export.gsub(/[%@]/, '')
        )

        if diffs.empty?
          Outcome.new(true, nil)
        else
          Outcome.new(
            false, nil, [],
            [
              Reportable.error(
                [@file_to_validate.last], # subtitle_import file
                [
                  'Text mismatch between subtitle/subtitle_tagging_export and content_at:',
                  diffs.join("\n")
                ]
              )
            ]
          )
        end
      end
    end
  end
end
