class Repositext
  class Validation
    # Validation to run before a Folio XML import.
    class FolioXmlPreImport < Validation

      # Specifies validations to run related to Folio Xml post import.
      def run_list
        validate_files(:folio_xml_sources) do |text_file|
          Validator::Utf8Encoding.new(text_file, @logger, @reporter, @options).run
          Validator::FolioImportRoundTrip.new(text_file, @logger, @reporter, @options).run
        end
      end

    end
  end
end
