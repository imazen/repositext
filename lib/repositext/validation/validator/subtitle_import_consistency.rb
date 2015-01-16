class Repositext
  class Validation
    class Validator
      # Depending on @options[:subtitle_import_consistency_compare_mode], validates:
      # * 'pre_import':
      #   that the text contents in subtitle/subtitle_tagging import still match those of content_at
      #   Purpose: To make sure that import is based on current content_at.
      # * 'post_import':
      #   that the subtitle/subtitle_tagging import file is identical to a
      #   subtitle export generated from the new content AT (with updated subtitle_marks)
      #   Purpose: To make sure that the import worked correctly and nothing
      #   was changed inadvertently.
      class SubtitleImportConsistency < Validator

        class TextMismatchError < ::StandardError; end

        # Runs all validations for self
        def run
          # @file_to_validate is an array with the content_at and
          # subtitle/subtitle_tagging_import files
          content_at_file, subtitle_import_file = @file_to_validate
          outcome = contents_match?(
            content_at_file.read,
            subtitle_import_file.read
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if contents match (depending on @options[:subtitle_import_consistency_compare_mode])
        # @param[String] content_at
        # @param[String] subtitle_import
        # @return[Outcome]
        def contents_match?(content_at, subtitle_import)
          # We have to export content_at in both cases to a temporary subtitle_export
          # so that we can compare it with the subtitle_import

          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = @options['kramdown_parser_class'].parse(content_at)
          doc = Kramdown::Document.new('')
          doc.root = root

          case @options[:subtitle_import_consistency_compare_mode]
          when 'pre_import'
            # We re-export the existing content_at to subtitle/subtitle_tagging
            # and compare the result with subtitle_import after removing
            # subtitle_marks and gap_marks in both since we expect them to change.
            tmp_subtitle_export = doc.send(@options['subtitle_converter_method_name'])
            string_1, string_2 = tmp_subtitle_export.gsub(/[%@]/, ''), subtitle_import.gsub(/[%@]/, '')
            error_message = "\n\nText mismatch between subtitle/subtitle_tagging_import and content_at in #{ @file_to_validate.last.path }."
          when 'post_import'
            # We re-export the new content_at to subtitle and compare the result
            # with subtitle_import. We leave all subtitle_marks and gap_marks
            # in place since they should be identical if everything works correctly.

            # Important: We need to always compare with subtitle_export, never
            # subtitle_tagging_export since we strip subtitle marks in the latter.
            tmp_subtitle_export = doc.send(@options['subtitle_export_converter_method_name'])
            string_1 = subtitle_import.gsub(/(?<! )(@+)\n\z/, ' \1' + "\n") # insert space before subtitle marks at the end of the file
            string_2 = tmp_subtitle_export
            error_message = "\n\nText mismatch between subtitle/subtitle_tagging_import and subtitle_export from content_at in #{ @file_to_validate.last.path }."
          else
            raise "Invalid compare mode: #{ @options[:subtitle_import_consistency_compare_mode].inspect }"
          end

          diffs = Suspension::StringComparer.compare(string_1, string_2)

          if diffs.empty?
            Outcome.new(true, nil)
          else
            # We want to terminate an import if the text is not consistent.
            # Normally we'd return a negative outcome (see below), but in this
            # case we raise an exception.
            # Outcome.new(
            #   false, nil, [],
            #   [
            #     Reportable.error(
            #       [@file_to_validate.last.path], # subtitle/subtitle_tagging_import file
            #       [
            #         'Text mismatch between subtitle/subtitle_tagging_import and content_at:',
            #         diffs.inspect
            #       ]
            #     )
            #   ]
            # )
            raise TextMismatchError.new(
              [
                error_message,
                "Cannot proceed with import. Please resolve text differences first:",
                diffs.inspect
              ].join("\n")
            )
          end
        end

      end
    end
  end
end
