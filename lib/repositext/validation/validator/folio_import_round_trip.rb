class Repositext
  class Validation
    class Validator
      # Checks if parsing the original folio xml and parsing the generated
      # kramdown AT produce identical kramdown trees.
      class FolioImportRoundTrip < Validator

        # Runs all validations for self
        def run
          xml_file = @file_to_validate
          outcome = valid_folio_round_trip?(xml_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      end

    private

      # @param xml_file [RFile::Xml]
      def valid_folio_round_trip?(xml_file)
        # parse Folio XML
        folio_based_kramdown_doc = @options['folio_xml_parser_class'].new(
          xml_file.contents
        ).parse_to_kramdown_document
        folio_based_kramdown_root = folio_based_kramdown_doc.root
        # Serialize kramdown doc to kramdown string
        folio_based_at_string = folio_based_kramdown_doc.send(
          @options['kramdown_converter_method_name']
        )
        # Parse back the generated kramdown string
        round_trip_kramdown_root = @options['kramdown_parser_class'].parse(
          folio_based_at_string
        ).first
        # compare the two kramdown trees
        diffs = folio_based_kramdown_root.compare_with(round_trip_kramdown_root)
        if diffs.empty?
          Outcome.new(true, nil)
        else
          Outcome.new(
            false, nil, [],
            diffs.map { |diff|
              Reportable.error(
                {
                  filename: xml_file.filename
                },
                ['Roundtrip comparison results in different elements', diff]
              )
            }
          )
        end
      end

    end
  end
end
