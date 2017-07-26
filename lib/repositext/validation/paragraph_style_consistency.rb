class Repositext
  class Validation
    # Validation to make sure that two files' paragraphs are consistent.
    class ParagraphStyleConsistency < Validation

      # Specifies validations to run for paragraph style consistency between
      # primary and foreign files.
      def run_list

        # Single files
        validate_files(:content_at_files) do |f_content_at_file|
          Validator::ParagraphStyleConsistency.new(
            [f_content_at_file, f_content_at_file.corresponding_primary_file],
            @logger,
            @reporter,
            @options
          ).run
        end
      end

    end
  end
end
