class Repositext
  class Validation
    class Validator

      # Validates syntax related aspects of DOCX import.
      class DocxImportSyntax < Validator

        # Runs all validations for self
        def run
          docx_file = @file_to_validate
          outcome = valid_docx_syntax?(docx_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param docx_file_name [String] absolute path to the docx file
        # @return [Outcome]
        def valid_docx_syntax?(docx_file)
          errors = []
          warnings = []

          document_xml_contents = docx_file.extract_docx_document_xml
          docx_parser = @options['docx_validation_parser_class'].new(
            document_xml_contents,
            {
              'validation_errors' => errors,
              'validation_warnings' => warnings,
              'validation_file_descriptor' => @file_to_validate,
              'validation_logger' => @logger,
            }
          )

          # validate_character_inventory(docx_parser, errors, warnings)
          validate_parse_tree(docx_parser, errors, warnings)

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Delegates validation to docx_parser. That parser collects reportables
        # into errors and warnings.
        # @param [Kramdown::Parser::VgrDocxValidation] docx_parser
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_parse_tree(docx_parser, errors, warnings)
          docx_parser.parse
        end

# TODO: Verify that docx doesn't contain soft returns:
# Unexpected element type br on line 2. Requires method "process_node_br".
# Provide context in error message
# Terminate import!

        # @param [Kramdown::Parser::VgrDocxValidation] docx_parser
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_character_inventory(docx_parser, errors, warnings)
        end

      end
    end
  end
end
