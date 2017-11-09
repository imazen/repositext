class Repositext
  class Validation
    class Validator
      # Depending on @options[:gap_mark_tagging_import_consistency_compare_mode], validates:
      # * 'pre_import':
      #   that the text contents in gap_mark_tagging_import still match those of content_at
      #   Purpose: To make sure that import is based on current content_at.
      # * 'post_import':
      #   that the gap_mark_tagging_import file is identical to a
      #   gap_mark_tagging_export generated from the new content AT (with updated gap_marks)
      #   Purpose: To make sure that the import worked correctly and nothing
      #   was changed inadvertently.
      class GapMarkTaggingImportConsistency < Validator

        class TextMismatchError < ::StandardError; end

        # Runs all validations for self
        def run
          # @file_to_validate is an array with the content_at and
          # gap_mark_tagging_import files
          content_at_file, gap_mark_tagging_import_file = @file_to_validate
          outcome = contents_match?(
            content_at_file.read,
            gap_mark_tagging_import_file.read
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if contents match (depending on @options[:gap_mark_tagging_import_consistency_compare_mode])
        # @param [String] content_at
        # @param [String] gap_mark_tagging_import
        # @return [Outcome]
        def contents_match?(content_at, gap_mark_tagging_import)
          # We have to export content_at in both cases to a temporary gap_mark_tagging_export
          # so that we can compare it with the gap_mark_tagging_import
          tmp_gap_mark_tagging_export = Repositext::Process::Export::GapMarkTagging.new(content_at).export.result
          case @options[:gap_mark_tagging_import_consistency_compare_mode]
          when 'pre_import'
            # We re-export the existing content_at to gap_mark_tagging
            # and compare the result with gap_mark_tagging_import after removing
            # subtitle_marks and gap_marks in both since we expect them to change.
            string_1 = Repositext::Process::Merge::GapMarkTaggingImportIntoContentAt.remove_gap_marks_and_omit_classes(tmp_gap_mark_tagging_export)
            string_2 = Repositext::Process::Merge::GapMarkTaggingImportIntoContentAt.remove_gap_marks_and_omit_classes(gap_mark_tagging_import)
            error_message = "\n\nText mismatch between gap_mark_tagging_import and content_at in #{ @file_to_validate.last.filename }."
          when 'post_import'
            # We re-export the new content_at to gap_mark_tagging and compare the result
            # with gap_mark_tagging_import. We remove subtitle_marks since they
            # are stripped during gap_mark_tagging export. We leave gap_marks in
            # place since they should be identical if everything works correctly.
            string_1 = gap_mark_tagging_import.gsub(/[@]/, '')
            string_2 = tmp_gap_mark_tagging_export.gsub(/[@]/, '')
            error_message = "\n\nText mismatch between gap_mark_tagging_import and gap_mark_tagging_export from content_at in #{ @file_to_validate.last.filename }."
          else
            raise "Invalid compare mode: #{ @options[:gap_mark_tagging_import_consistency_compare_mode].inspect }"
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
            #       [@file_to_validate.last], # gap_mark_tagging_import file
            #       [
            #         'Text mismatch between gap_mark_tagging_import and content_at:',
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
