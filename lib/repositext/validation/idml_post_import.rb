class Repositext
  class Validation
    class IdmlPostImport < Validation

      # Specifies validations to run related to Idml import.
      def run_list
        validate_files(:imported_repositext_files) do |file_name|
          Validator::Utf8Encoding.new(
            file_name, @logger, @reporter, @options
          ).run
        end
        validate_files(:imported_at_files) do |file_name|
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            file_name, @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
