class Repositext
  class Validation
    class Validator

      # Checks if parsing the exported docx produces kramdown AT identical to
      # the contents of the source content AT file.
      class DocxExportConsistency < Validator

        # Runs all validations for self
        def run
          docx_file = @file_to_validate
          outcome = exported_docx_consistent_with_source_content_at?(docx_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param docx_file [RFile::Docx]
        # @return [Outcome]
        def exported_docx_consistent_with_source_content_at?(docx_file)
          document_xml_contents = docx_file.extract_docx_document_xml
          # parse Docx
          docx_based_kramdown_root, _warnings = @options['docx_parser_class'].parse(
            document_xml_contents,
          )
          docx_based_kramdown_doc = Kramdown::Document.new('_', line_width: 100000)
          docx_based_kramdown_doc.root = docx_based_kramdown_root
          # Serialize kramdown doc to kramdown string
          docx_based_at_string = docx_based_kramdown_doc.send(
            @options['kramdown_converter_method_name']
          )
          sanitized_docx_based_at_string = sanitize_docx_based_at_string(docx_based_at_string)
          # Get source content AT
          c_s_at_f = docx_file.corresponding_content_at_file
          source_content_at = c_s_at_f.contents
          sanitized_source_content_at = sanitize_source_content_at(source_content_at)
          # Compare source content AT with docx based AT
          diffs = Suspension::StringComparer.compare(
            sanitized_source_content_at,
            sanitized_docx_based_at_string
          )

          if diffs.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              diffs.map { |diff|
                Reportable.error(
                  { filename: docx_file.filename },
                  ['Roundtrip comparison results in different content AT', diff]
                )
              }
            )
          end
        end

        # Prepares source_content_at for comparison
        # @param source_content_at [String]
        # @return [String]
        def sanitize_source_content_at(source_content_at)
          # Remove id page
          r, _id_page = Repositext::Utils::IdPageRemover.remove(source_content_at)
          # Normalize trailing newlines
          r.sub!(/\n+\z/, "\n")
          # Remove record_marks, subtitle_marks, and gap_marks
          r.gsub!(/^\^\^\^[^\n]+\n\n/, '')
          # Remove line_break periods and IALs in various combinations
          r.gsub!('*{: .italic .smcaps} *.*{: .line_break}*', ' ')
          r.gsub!('*{: .smcaps} *.*{: .line_break}*', ' ')
          r.gsub!('*.*{: .line_break}', '')
          # Change .song_break to .song
          r = replace_ial_classes(r, %w[song_break], ' .song')
          # Remove certain IAL classes
          r = replace_ial_classes(
            r,
            %w[
              decreased_word_space
              first_par
              increased_word_space
              indent_for_eagle
              no_highlight
              omit
            ],
            ''
          )
          # Remove empty block level IALs. They may occur after certain ial
          # classes have been removed. Example:
          #     # *Word*{: .italic .smcaps}
          #     {:}
          r.gsub!(/^\{:\}\n/, '')
          r
        end

        def sanitize_docx_based_at_string(docx_based_at_string)
          # Remove id page
          r, _id_page = Repositext::Utils::IdPageRemover.remove(docx_based_at_string)
          # Change tabs around eagles to spaces
          r.gsub!(/\t/, " ")
          r.gsub!(/\t/, " ")
          # Normalize trailing newlines
          r.sub!(/\n+\z/, "\n")
          # Remove certain IAL classes
          r = replace_ial_classes(r, %w[first_par], '')
          # Remove empty block level IALs. They may occur after certain ial
          # classes have been removed. Example:
          #     # *Word*{: .italic .smcaps}
          #     {:}
          r.gsub!(/^\{:\}\n/, '')
          r
        end

        # Replaces class_names from inline and block level IALs in txt with
        # replacement.
        # Returns copy of txt with class_names removed.
        # @param txt [String]
        # @param class_names [Array<String>]
        # @param replacement [String]
        # @return [String]
        def replace_ial_classes(txt, class_names, replacement)
          # I have to process each class_name separately. Otherwise only one
          # instance of the unwanted class_names will be removed if multiple
          # exist in a single IAL
          class_names.inject(txt) { |m,e|
            m.gsub(
              /
                (\{:[^\}]*) # capture group 1 start of block or inline IAL
                \s
                (\.#{ Regexp.escape(e) }) #  capture group 2 class names to remove
                \b # word boundary of class name
                ([^\}]*\}) # capture group 3 end of IAL
              /x,
              '\1' + replacement + '\3'
            )
          }
        end

      end
    end
  end
end
