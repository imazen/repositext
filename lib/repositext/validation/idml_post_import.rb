class Repositext
  class Validation
    # Validation to run after an IDML import.
    class IdmlPostImport < Validation

      # Specifies validations to run related to Idml import.
      def run_list
        config = @options['config']
        # Single files
        validate_files(:imported_repositext_files) do |text_file|
          Validator::Utf8Encoding.new(
            text_file, @logger, @reporter, @options
          ).run
        end
        validate_files(:imported_at_files) do |content_at_file|
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            content_at_file,
            @logger,
            @reporter,
            @options.merge(
              "validator_invalid_gap_mark_regex" => config.setting(:validator_invalid_gap_mark_regex),
              "validator_invalid_subtitle_mark_regex" => config.setting(:validator_invalid_subtitle_mark_regex)
            )
          ).run
        end

      end

    end
  end
end
