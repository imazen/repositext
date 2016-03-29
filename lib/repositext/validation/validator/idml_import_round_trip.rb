class Repositext
  class Validation
    class Validator
      # Checks if parsing the original Idml and parsing the generated
      # kramdown AT produce identical kramdown trees.
      class IdmlImportRoundTrip < Validator

        # Runs all validations for self
        def run
          document_to_validate = ::File.binread(@file_to_validate.path)
          outcome = valid_idml_round_trip?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param [String] idml_file_contents
        def valid_idml_round_trip?(idml_file_contents)
          # parse Idml
          idml_based_kramdown_doc = @options['idml_parser_class'].new(
            idml_file_contents
          ).parse
          idml_based_kramdown_root = idml_based_kramdown_doc.root
          # Serialize kramdown doc to kramdown string
          idml_based_at_string = idml_based_kramdown_doc.send(
            @options['kramdown_converter_method_name']
          )
          # Parse back the generated kramdown string
          round_trip_kramdown_root = @options['kramdown_parser_class'].parse(
            idml_based_at_string
          ).first
          # compare the two kramdown trees
          diffs = idml_based_kramdown_root.compare_with(round_trip_kramdown_root)
          if diffs.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              diffs.map { |diff|
                Reportable.error(
                  [@file_to_validate.path],
                  ['Roundtrip comparison results in different elements', diff]
                )
              }
            )
          end
        end

      end
    end
  end
end
