class Repositext
  class Validation
    class Validator
      # Validates that a docx imported foreign content AT file is consistent
      # with the corresponding primary file.
      class DocxImportForeignConsistency < Validator

        # Runs all validations for self
        def run
          f_content_at_file = @file_to_validate
          p_content_at_file = f_content_at_file.corresponding_primary_file
          outcome = foreign_content_at_consistent?(f_content_at_file, p_content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @return [Outcome]
        def foreign_content_at_consistent?(f_content_at_file, p_content_at_file)
          errors = []
          warnings = []
          f_cat = f_content_at_file
          p_cat = p_content_at_file
          find_inconsistent_eagles(f_cat, p_cat, errors, warnings)
          find_inconsistent_id_titles(f_cat, p_cat, errors, warnings)
          find_inconsistent_paragraph_numbers(f_cat, p_cat, errors, warnings)
          find_inconsistent_plain_text(f_cat, p_cat, errors, warnings)
          Outcome.new(
            errors.empty?,
            nil,
            [],
            errors,
            warnings
          )
        end

        # Validates that foreign eagles appear in the same proportional character
        # positions and the primary eagles.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        # Mutates errors and warnings in place
        def find_inconsistent_eagles(f_content_at_file, p_content_at_file, errors, warnings)
          # Returns proportional positions of eagles in s.
          # 0.0 is at the beginning and 1.0 is at the end.
          # @param s [String]
          # @param len [Float]
          eagle_finder = ->(s, len) {
            i = -1
            eagle_positions = []
            while(i = s.index('', i+1))
              eagle_positions << (i / len)
            end
            eagle_positions
          }
          f_pt = f_content_at_file.plain_text_contents({})
          f_pt_len = f_pt.length
          p_pt = p_content_at_file.plain_text_contents({})
          p_pt_len = p_pt.length
          foreign_eagle_char_positions = eagle_finder.call(f_pt, f_pt_len.to_f)
          primary_eagle_char_positions = eagle_finder.call(p_pt, p_pt_len.to_f)

          tolerance_factor = 0.1
          diffs = Repositext::Utils::ArrayDiffer.diff_simple(
            primary_eagle_char_positions,
            foreign_eagle_char_positions
          )
          diffs.each { |e|
            # [
            #     [
            #       "!",
            #       0.0006000600060006001,
            #       0.0006519251749554296
            #     ],
            #     [
            #       "!",
            #       0.9999739104345217,
            #       0.9931215241744499
            #     ]
            # ]
            error_detail = case e.first
            when '-'
              "Foreign is missing eagle at primary #{ (e.last * p_pt_len * 100).round }% character position."
            when '+'
              "Foreign has extra eagle at #{ (e.last * f_pt_len * 100).round }% character position."
            when '!'
              delta = (e[1] - e[2]).abs
              if delta >= (e[1] * tolerance_factor)
                [
                  "Foreign eagle character position at #{ (e[2] * f_pt_len * 100).round }% ",
                  "is significantly different from primary position at #{ (e[1] * p_pt_len * 100).round }%."
                ].join
              else
                nil
              end
            else
              raise "Handle this: #{ e.inspect }"
            end
            if error_detail
              errors << Reportable.error(
                [f_content_at_file.filename],
                [
                  "Foreign eagle is inconsistent with primary",
                  error_detail
                ]
              )
            end
          }
        end

        # Validates that English titles in id page are consistent with original
        # English file.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        # Mutates errors and warnings in place
        def find_inconsistent_id_titles(f_content_at_file, p_content_at_file, errors, warnings)
          f_id_parts = Repositext::Services::ExtractContentAtIdParts.call(
            f_content_at_file.contents
          ).result
          p_id_parts = Repositext::Services::ExtractContentAtIdParts.call(
            p_content_at_file.contents
          ).result

          # Verify that the English title in the id_title2 paragraph is the same
          # as the title in the corresponding English file.
          f_title = if (f_id_title2 = f_id_parts['id_title2'].first)
            f_id_title2.gsub(/[\(\)]/, '')
          end
          p_title = p_id_parts['id_title1'].first

          if f_title.nil?
            errors << Reportable.error(
              [f_content_at_file.filename],
              ["Foreign .id_title2 is missing."]
            )
          elsif p_title.nil?
            errors << Reportable.error(
              [p_content_at_file.filename],
              ["Primary .id_title1 is missing."]
            )
          elsif !p_title.index("*#{ f_title }*")
            errors << Reportable.error(
              [f_content_at_file.filename],
              [
                "Foreign .id_title2 is inconsistent with English .id_title1.",
                "Foreign: #{ f_title.inspect }, English: #{ p_title.inspect }."
              ]
            )
          end

          # Verify that the date code and language abbreviation exist and are
          # correct in the id_title1.
          if(f_id_title1 = f_id_parts['id_title1'].first)
            # ImplementationTag #date_code_regex
            f_lang_and_date_code_from_id = f_id_title1[/[a-z]{3}\d{2}-\d{4}[a-z]?/i].downcase
            f_lang_and_date_code_from_file = [
              f_content_at_file.lang_code_3,
              f_content_at_file.extract_date_code,
            ].join
          else
            errors << Reportable.error(
              [f_content_at_file.filename],
              [
                "Foreign language and date code in .id_title1 is inconsistent with those from file name.",
                ".id_title1: #{ f_lang_and_date_code_from_id.inspect }, file name: #{ f_lang_and_date_code_from_file.inspect }."
              ]
            )
          end

          # Verify that the Title_of_Sermon and the id_title match.
          # TODO: What does this mean?
        end

        # Validates that foreign paragraph numbers are consistent with primary ones.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        # Mutates errors and warnings in place
        def find_inconsistent_paragraph_numbers(f_content_at_file, p_content_at_file, errors, warnings)
          # Get foreign paragraph numbers
          f_kramdown_doc = Kramdown::Document.new(
            f_content_at_file.contents,
            input: 'KramdownRepositext'
          )
          f_tree_structure = Kramdown::TreeStructureExtractor.new(f_kramdown_doc).extract
          # [:paragraph_numbers] is an array of Hashes:
          #     {
          #       :paragraph_number => "header",
          #       :line => 3
          #     }
          f_paragraph_numbers = f_tree_structure[:paragraph_numbers].map{ |e| e[:paragraph_number] }.find_all { |e|
            e =~ /\A\d/
          }

          # Get primary paragraph numbers
          p_kramdown_doc = Kramdown::Document.new(
            p_content_at_file.contents,
            input: 'KramdownRepositext'
          )
          p_tree_structure = Kramdown::TreeStructureExtractor.new(p_kramdown_doc).extract
          p_paragraph_numbers = p_tree_structure[:paragraph_numbers].map{ |e| e[:paragraph_number] }.find_all { |e|
            e =~ /\A\d/
          }
          diffs = Repositext::Utils::ArrayDiffer.diff_simple(
            p_paragraph_numbers,
            f_paragraph_numbers
          )
          diffs.each { |e|
            # [["-", "a"],
            #  ["-", "b"],
            #  ["!", "x", "y"],
            #  ["+", "d"],
            #  ["+", "g"],
            #  ["+", "h"]]
            error_detail = case e.first
            when '-'
              "#{ e.last.inspect } is missing in foreign."
            when '+'
              "#{ e.last.inspect } is extra in foreign."
            when '!'
              "#{ e[1].inspect } is different in foreign: #{ e[2].inspect }."
            else
              raise "Handle this: #{ e.inspect }"
            end
            errors << Reportable.error(
              [f_content_at_file.filename],
              [
                "Foreign paragraph number is inconsistent with primary",
                error_detail
              ]
            )
          }
          true
        end

        # Validates that plain text from DOCX is consistent with plain text
        # from imported content AT.
        # @param f_content_at_file [RFile::ContentAt]
        # @param p_content_at_file [RFile::ContentAt]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        # Mutates errors and warnings in place
        def find_inconsistent_plain_text(f_content_at_file, p_content_at_file, errors, warnings)
          docx_import_plain_text = Repositext::Services::ExtractTextFromDocx.call(
            f_content_at_file.corresponding_docx_import_filename
          ).result
          content_at_plain_text = f_content_at_file.plain_text_for_docx_import_validation_contents({})

          diffs = Suspension::StringComparer.compare(docx_import_plain_text, content_at_plain_text)

          diffs.each { |diff|
            errors << Reportable.error(
              [f_content_at_file.filename],
              [
                'Plain text difference between docx and content_at',
                diff.inspect
              ]
            )
          }
        end

      end

    end
  end
end
