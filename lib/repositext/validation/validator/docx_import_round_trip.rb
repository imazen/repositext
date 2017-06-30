class Repositext
  class Validation
    class Validator

      # Checks if parsing the original Docx and parsing the generated
      # kramdown AT produce identical kramdown trees.
      class DocxImportRoundTrip < Validator

        # Runs all validations for self
        def run
          outcome = valid_docx_round_trip?(@file_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param docx_file_name [String] absolute path to the docx file
        # @return [Outcome]
        def valid_docx_round_trip?(docx_file_name)
          content_type = @options['content_type']
          language = content_type.language
          contents = File.binread(docx_file_name).freeze
          docx_file = Repositext::RFile::Docx.new(
            contents, language, docx_file_name, content_type
          )

          document_xml_contents = docx_file.extract_docx_document_xml
          # parse Docx
          docx_based_kramdown_root, _warnings = @options['docx_parser_class'].parse(
            document_xml_contents,
          )
          docx_based_kramdown_doc = Kramdown::Document.new('_')
          docx_based_kramdown_doc.root = docx_based_kramdown_root
          # Serialize kramdown doc to kramdown string
          docx_based_at_string = docx_based_kramdown_doc.send(
            @options['kramdown_converter_method_name']
          )
          # Parse back the generated kramdown string
          round_trip_kramdown_root = @options['kramdown_parser_class'].parse(
            docx_based_at_string
          ).first
          # compare the two kramdown trees
          diffs = docx_based_kramdown_root.compare_with(round_trip_kramdown_root)
          if diffs.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              diffs.map { |diff|
                Reportable.error(
                  [docx_file.filename],
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
