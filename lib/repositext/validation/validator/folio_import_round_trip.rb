class Repositext
  class Validation
    class Validator
      # Checks if parsing the original folio xml and parsing the generated
      # kramdown AT produce identical kramdown trees.
      class FolioImportRoundTrip < Validator

        # Runs all validations for self
        def run
          document_to_validate = ::File.read(@file_to_validate)
          errors, warnings = [], []

          catch(:abandon) do
            outcome = valid_folio_round_trip?(document_to_validate)
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      end

    private

      # @param[String] folio_xml_document
      def valid_folio_round_trip?(folio_xml_document)
        # parse Folio XML
        folio_based_kramdown_doc = @options['folio_xml_parser_class'].new(
          folio_xml_document
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
            [
              Reportable.error(
                [@file_to_validate],
                [diffs.join("\n")]
              )
            ]
          )
        end
      end

    end
  end
end
