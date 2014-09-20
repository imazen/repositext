class Repositext
  class Validation
    class FolioXmlPostImport < Validation

      # Specifies validations to run related to Folio Xml post import.
      def run_list
        validate_files(:imported_repositext_files) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
        end
        validate_files(:imported_at_files) do |path|
          @options['run_options'] << 'kramdown_syntax_at-all_elements_are_inside_record_mark'
          Validator::KramdownSyntaxAt.new(
            File.open(path),
            @logger,
            @reporter,
            @options
          ).run
        end
      end

    end
  end
end
