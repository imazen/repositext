class Repositext
  class Validation
    # Validation to run before a Folio XML import.
    class FolioXmlPreImport < Validation

      # Specifies validations to run related to Folio Xml post import.
      def run_list
        validate_files(:folio_xml_sources) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
          Validator::FolioImportRoundTrip.new(File.open(path), @logger, @reporter, @options).run
        end
      end

    end
  end
end
