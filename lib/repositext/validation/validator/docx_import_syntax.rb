class Repositext
  class Validation
    class Validator

      # Validates syntax related aspects of DOCX import.
      class DocxImportSyntax < Validator

        # Runs all validations for self
        def run
          outcome = valid_docx_syntax?(@file_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param docx_file_name [String] absolute path to the docx file
        # @return [Outcome]
        def valid_docx_syntax?(docx_file_name)
          repository = @options['repository']
          language = repository.language
          contents = File.binread(docx_file_name).freeze
          docx_file = Repositext::RFile::Binary.new(
            contents, language, docx_file_name, repository
          )

          errors = []
          warnings = []

          document_xml_contents = docx_file.extract_docx_document_xml
          docx_parser = @options['docx_validation_parser_class'].new(
            document_xml_contents,
            {}
          )

          # validate_character_inventory(docx_parser, errors, warnings)
          # validate_parse_tree(docx_parser, errors, warnings)

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Delegates validation to docx_parser. That parser collects reportables
        # into errors and warnings.
        # @param [Kramdown::Parser::VgrDocxValidation] docx_parser
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_parse_tree(docx_parser, errors, warnings)
          docx_parser.parse(
            docx_parser.stories_to_import,
            {
              'validation_errors' => errors,
              'validation_warnings' => warnings,
              'validation_file_descriptor' => @file_to_validate.path,
              'validation_logger' => @logger,
            }
          )
        end

# TODO: Verify that docx doesn't contain soft returns:
# Unexpected element type br on line 2. Requires method "process_node_br".
# Provide context in error message
# Terminate import!

        # @param [Kramdown::Parser::VgrDocxValidation] docx_parser
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_character_inventory(docx_parser, errors, warnings)
          docx = docx_parser.stories_to_import.first
          docx_name = docx.name
          docx_source = docx.body
          # Detect invalid characters
          str_sc = Kramdown::Utils::StringScanner.new(docx_source)
          while !str_sc.eos? do
            if (match = str_sc.scan_until(
              Regexp.union(Repositext::Validation::Config::INVALID_CHARACTER_REGEXES)
            ))
              errors << Reportable.error(
                [
                  @file_to_validate.path,
                  sprintf("story %5s", docx_name),
                  sprintf("line %5s", str_sc.current_line_number)
                ],
                ['Invalid character', sprintf('U+%04X', match[-1].codepoints.first)]
              )
            else
              break
            end
          end
          # Build character inventory
          if 'debug' == @logger.level
            chars = Hash.new(0)
            ignored_chars = [0x30..0x39, 0x41..0x5A, 0x61..0x7A]
            docx_source.codepoints.each { |cp|
              chars[cp] += 1  unless ignored_chars.any? { |r| r.include?(cp) }
            }
            chars = chars.sort_by { |k,v|
              k
            }.map { |(code,count)|
              sprintf("U+%04x  #{ code.chr('UTF-8') }  %5d", code, count)
            }
            @reporter.add_stat(
              Reportable.stat([@file_to_validate.path], ['Character Histogram', chars])
            )
          end
        end

      end
    end
  end
end
