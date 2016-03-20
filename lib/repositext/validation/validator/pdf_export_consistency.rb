class Repositext
  class Validation
    class Validator

      # Validates consistency of exported pdf content with content AT.
      class PdfExportConsistency < Validator

        # Runs all validations for self
        def run
          outcome = pdf_export_consistent?(@file_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param pdf_file_name [String] absolute path to the PDF file
        # @return [Outcome]
        def pdf_export_consistent?(pdf_file_name)
          repository = @options['repository']
          language = repository.language
          pdf_file_stub = Repositext::RFile::Binary.new(
            '_', language, pdf_file_name, repository
          )
          corresponding_content_at_file = pdf_file_stub.corresponding_content_at_file

          pdf_raw_text = extract_pdf_raw_text(
            pdf_file_name,
            @options['extract_text_from_pdf_service']
          )
          content_at_plain_text = corresponding_content_at_file.plain_text_contents(
            convert_smcaps_to_upper_case: true
          )

          errors = []
          warnings = []

          validate_content_consistency(pdf_raw_text, content_at_plain_text, errors, warnings)
          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Extracts raw text from pdf_file_name
        # @param pdf_file_name [String]
        # @param extract_text_from_pdf_service [Services::ExtractTextFromPdf]
        def extract_pdf_raw_text(pdf_file_name, extract_text_from_pdf_service)
          extract_text_from_pdf_service.extract(pdf_file_name)
        end

        # Validates that contents of pdf_raw_text and content_at are consistent.
        # Mutates `errors` and `warnings` in place.
        # @param pdf_raw_text [String]
        # @param content_at_plain_text [String]
        # @param [Array] errors collector for errors
        # @param [Array] warnings collector for warnings
        def validate_content_consistency(pdf_raw_text, content_at_plain_text, errors, warnings)
          pdf_plain_text = sanitize_pdf_raw_text(pdf_raw_text)
          c_at_pt = sanitize_content_at_plain_text(content_at_plain_text)

          all_diffs_with_context = Suspension::StringComparer.compare(
            c_at_pt,
            pdf_plain_text,
            true, # include context
            false # include all diffs
          )

          # find insert [1], delete [-1], and change [-1,1] groups
          diff_groups = []
          current_diff_group = nil
          all_diffs_with_context.each { |diff|
            ins_del, txt_diff, location, context = diff
            case ins_del
            when -1
              if current_diff_group.nil?
                # A -1 always starts a new group
                current_diff_group = [diff]
              else
                # We don't expect to see a -1 if we already have a current_diff_group
                raise "Unexpected -1: #{ diff.inspect }"
              end
            when 0
              # 0 closes any diff groups
              if current_diff_group
                diff_groups << current_diff_group
                current_diff_group = nil
              end
            when 1
              if current_diff_group.nil?
                # An insertion
                current_diff_group = [diff]
              else
                # This is a change. We already have a -1
                current_diff_group << diff
              end
            else
              raise "handle this: #{ ins_del.inspect }"
            end
            if current_diff_group && current_diff_group.length > 2
              # No diff group should have more than 2 elements
              raise "Handle this: #{ current_diff_group.inspect }"
            end
          }
          # Finalize any started diff group
          if current_diff_group
            diff_groups << current_diff_group
            current_diff_group = nil
          end

          # Process each diff_group
          diff_groups.each { |diff_group|

            ins_del_signature = diff_group.map { |e| e.first }
            description = nil
            text_difference = nil

            case ins_del_signature
            when [-1]
              # Deletion
              ins_del, txt_diff, location, context = diff_group.first

              # Ignore missing horizontal_rule in PDF
              next  if "* * * * * * *\n" == txt_diff

              # Prepare error reporting data
              description = "Missing "
              text_difference = txt_diff.inspect
            when [-1,1]
              # Change

              # Get each diff. They consist of
              # ins_del, txt_diff, location, and context
              del, ins = diff_group

              # Ignore any mismatches caused by PDF line wrapping.
              # Space is changed to a newline.
              next  if ' ' == del[1] && "\n" == ins[1]

              # Prepare error reporting data
              description = "Changed "
              text_difference = "#{ del[1].inspect } to #{ ins[1].inspect }"
            when [1]
              # Addition
              ins_del, txt_diff, location, context = diff_group.first

              # Ignore any mismatches caused by PDF line wrapping.
              # Newline is inserted after elipsis, emdash, or hyphen.
              next  if "\n" == txt_diff && context =~ /[…—-]\n/

              # Ignore extra spaces inserted before punctuation [!?’”]
              # We look at the 21st and 22nd char in context
              next  if ' ' == txt_diff && context[20,2] =~ /\s[\!\?\’\”]/

              # Prepare error reporting data
              description = "Extra "
              text_difference = diff_group.first[1].inspect
            else
              raise "Handle this: #{ diff_group.inspect }"
            end

            context = diff_group.first[3].inspect
            description << %(#{ text_difference } in #{ context })
            errors << Reportable.error(
              [@file_to_validate],
              [
                'Difference between content_at and pdf_export',
                description,
              ]
            )

          }
        end

        # Sanitizes pdf_raw_text.
        # @param pdf_raw_text [String]
        # @return [String]
        def sanitize_pdf_raw_text(pdf_raw_text)
          sanitized_text = pdf_raw_text.dup

          # Trim leading and trailing whitespace
          sanitized_text.strip!

          # Remove revision information at the end of the doc
          sanitized_text.gsub!(/\sRevision\sInformation\sDate.+\z/m, '')

          # Clean up an edge case where a space is inserted before a question
          # mark, and a newline is inserted after the question mark.
          # This occurs a couple times in all files and is best handled here
          # since it's spread over three diffs: -1 '?', 0 ' ', 1 '?\n'
          # We convert "word ?\nWord" => "word?\nWord"
          # We don't touch instances like "word…?… ?". These are legitimate.
          sanitized_text.gsub!(
            /
              (?<!…) # not preceded by ellipsis
              \s # a single space
              \? # a question mark
              \n # a newline
            /x,
            "?\n"
          )

          # Append newline and return
          sanitized_text + "\n"
        end

        # Sanitizes content_at_plain_text.
        # @param content_at_plain_text [String]
        # @return [String]
        def sanitize_content_at_plain_text(content_at_plain_text)
          sanitized_text = content_at_plain_text.dup

          # Trim leading and trailing whitespace
          sanitized_text.strip!

          # Append newline and return
          sanitized_text + "\n"
        end

      end
    end
  end
end
