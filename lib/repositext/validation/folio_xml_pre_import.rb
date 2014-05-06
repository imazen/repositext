class Repositext
  class Validation
    class FolioXmlPreImport < Validation

      # Specifies validations to run related to Folio Xml post import.
      def run_list
        validate_files(:folio_xml_sources) do |file_name|
          Validator::Utf8Encoding.new(file_name, @logger, @reporter, @options).run
          Validator::FolioImportRoundTrip.new(file_name, @logger, @reporter, @options).run
        end
      end

    end
  end
end
