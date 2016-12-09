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
          content_type = @options['content_type']
          config = content_type.config
          language = content_type.language

          pdf_file_stub = Repositext::RFile::Pdf.new(
            '_', language, pdf_file_name, content_type
          )
          corresponding_content_at_file = pdf_file_stub.corresponding_content_at_file

          if(
            @options[:skip_file_proc] &&
            ccafn = pdf_file_stub.corresponding_content_at_filename &&
            @options[:skip_file_proc].call(
              corresponding_content_at_file.contents,
              ccafn
            )
          )
            # When exporting PDF recording, we only export files that contain
            # gap_marks. So we need to check in the validation as well...
            $stderr.puts " - Skipping #{ filename } - matches options[:skip_file_proc]"
            return [Outcome.new(true, nil, [])]
          end

          pdf_raw_text = extract_pdf_raw_text(
            pdf_file_name,
            @options['extract_text_from_pdf_service'],
            @options['pdfbox_text_extraction_options']
          )
          content_at_plain_text = corresponding_content_at_file.plain_text_contents(
            convert_smcaps_to_upper_case: true
          )
          # We have to reload settings at the file level to get all required
          # settings.
          # NOTE: Can't use @options['...'] since that is not updated per file
          # for validations, just for the export in Repositext::Cli::Export#export_pdf_base
          config.update_for_file(corresponding_content_at_file.corresponding_data_json_filename)

          adjusted_content_at_plain_text = adjust_plain_text(
            content_at_plain_text,
            corresponding_content_at_file,
            config
          )

          errors = []
          warnings = []

          validate_content_consistency(
            pdf_raw_text,
            adjusted_content_at_plain_text,
            errors,
            warnings,
            config
          )
          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Extracts raw text from pdf_file_name
        # @param pdf_file_name [String]
        # @param extract_text_from_pdf_service [Services::ExtractTextFromPdf]
        # @param pdfbox_text_extraction_options [Hash], e.g., `{ spacing_tolerance: 0.3 }`
        def extract_pdf_raw_text(pdf_file_name, extract_text_from_pdf_service, pdfbox_text_extraction_options)
          extract_text_from_pdf_service.extract(
            pdf_file_name,
            pdfbox_text_extraction_options
          )
        end

        # Adjusts the content at based plain text to contain the same elements
        # as the extracted pdf plain text (id section).
        # @param plain_text [String] plain text as exported from content AT
        # @param content_at_file [RFile::ContentAt]
        # @param config [Repositext::Cli::Config] config for file
        def adjust_plain_text(plain_text, content_at_file, config)
          appendix = []

          # Append id contents only if file has id
          if content_at_file.contents.index('.id_paragraph')
            add_rt_id_paragraph_environment_contents(appendix, content_at_file, config)
          end

          # Append RtIdRecording
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_recording, false))
          # Append RtIdSeries
          if (rtids = config.setting(:pdf_export_id_series, false))
            appendix << convert_latex_to_plain_text(rtids)
            # The RtIdParagraph may not be in the content AT file but in the
            # id_series setting. If so, then we need to append additional content
            # here.
            if rtids.index('RtIdParagraph')
              add_rt_id_paragraph_environment_contents(appendix, content_at_file, config)
            end
          end

          # Remove nils, join with space before and between each segment
          r = plain_text + ' ' + appendix.compact.join(' ')
          # squeeze whitespace runs (e.g., "\n ")
          r.gsub(/\s{2,}/, ' ')
        end

        # Appends text that will be rendered after RtIdParagraph environment.
        # Modifies appendix in place.
        # @param appendix [Array] will be appended to in place
        # @param content_at_file [RFile::ContentAt]
        # @param config [Repositext::Cli::Config]
        def add_rt_id_paragraph_environment_contents(appendix, content_at_file, config)
          # Append RtIdExtraLanguageInfo
          appendix << config.setting(:pdf_export_id_extra_language_info, false)
          # Append RtIdLanguage (foreign only)
          if !config.setting(:is_primary_repo)
            # TODO: clean up method chain!
            appendix << content_at_file.content_type.language.name.upcase
          end
          # Append RtIdCopyrightYear
          appendix << %(©#{ config.setting(:erp_id_copyright_year, false) } #{ config.setting(:company_short_name) }, ALL RIGHTS RESERVED)
          # Append RtIdWriteToSecondary
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_write_to_secondary, false))
          # Append RtIdAddressSecondaryFirst
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_address_secondary_latex_1, false))
          # Append RtIdAddressSecondarySecond
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_address_secondary_latex_2, false))
          # Append RtIdAddressSecondaryThird
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_address_secondary_latex_3, false))
          # Append RtIdWriteToPrimary
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_write_to_primary, false))
          # Append RtIdAddressPrimaryFirst
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_address_primary_latex_1, false))
          # Append RtIdAddressPrimarySecond
          appendix << convert_latex_to_plain_text(config.setting(:pdf_export_id_address_primary_latex_2, false))
          # Append RtIdWebMaybePhone
          if config.setting(:is_primary_repo)
            # NOTE: in the template the two spaces around the period are \u2003 em-space.
            # That gets lost in the pdf extraction, so we use regular spaces here.
            appendix << %(#{ config.setting(:company_phone_number) } . #{ config.setting(:company_web_address) })
          else
            appendix << config.setting(:company_web_address)
          end
        end

        # Validates that contents of pdf_raw_text and content_at are consistent.
        # Mutates `errors` and `warnings` in place.
        # @param pdf_raw_text [String]
        # @param content_at_plain_text [String]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        # @param file_level_settings [Hash], stringified keys
        def validate_content_consistency(pdf_raw_text, content_at_plain_text, errors, warnings, file_level_settings)
          pdf_plain_text = sanitize_pdf_raw_text(pdf_raw_text)
          c_at_pt = sanitize_content_at_plain_text(content_at_plain_text)

          excerpt_window = 80 # to check if we're within 80 characters of an eagle
          all_diffs_with_context = Suspension::StringComparer.compare(
            c_at_pt,
            pdf_plain_text,
            true, # include context
            false, # include all diffs
            { excerpt_window: excerpt_window }
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
            text_diffs = nil

            case ins_del_signature
            when [-1]
              # Deletion
              ins_del, txt_diff, location, context = diff_group.first
              text_diffs = [txt_diff]

              # Ignore missing horizontal_rule in PDF
              next  if "* * * * * * *" == txt_diff.strip

              # With drop cap first eagle, pdf extractor gets confused and
              # doesn't insert a space (for same paragraph) or newline (for two
              # separate paragraphs) between the first and second line.
              # It's safe to ignore.
              next  if(([' ', "\n"].include?(txt_diff)) && (context[0,excerpt_window].index("\n")))

              # Titles with explicit linebreaks are missing a space, ignore.
              # We match on all caps letters: "WORD WORD \nWORD WORD"
              next  if((' ' == txt_diff) && (context =~ /[A-Z\s]{10,} \n[A-Z\s]{5,}/))

              # Prepare error reporting data
              description = "Missing "
              text_difference = txt_diff.inspect
            when [-1,1]
              # Change

              # Get each diff. They consist of
              # ins_del, txt_diff, location, and context
              del, ins = diff_group
              text_diffs = [del, ins].map { |e| e[1] }

              # Ignore any mismatches caused by PDF line wrapping.
              # Space is changed to a newline.
              next  if(' ' == del[1] && "\n" == ins[1])

              # Ignore custom formats for horizontal rules.
              # Asterisks are changed to stars
              next  if('*' == del[1] && "✩" == ins[1])

              # Prepare error reporting data
              description = "Changed "
              text_difference = "#{ del[1].inspect } to #{ ins[1].inspect }"
            when [1]
              # Addition
              ins_del, txt_diff, location, context = diff_group.first
              text_diffs = [txt_diff]

              # Ignore any mismatches caused by PDF line wrapping.
              # Newline is inserted after elipsis, emdash, or hyphen.
              next  if("\n" == txt_diff && context =~ /[…—-]\n/)
              # Newline is inserted before elipsis, emdash, or hyphen.
              next  if("\n" == txt_diff && context =~ /\n[…—-]/)
              # Newline is inserted after eagle "\n\n"
              next  if("\n" == txt_diff && context.index("\n\n"))

              # Ignore extra spaces inserted before punctuation [!?’”.]
              # We look at the 1st and 2nd char in trailing context, or the
              # entire context if it is too short
              next  if(' ' == txt_diff && (context[excerpt_window,2] || context) =~ /\s[\!\?\’\”\.]/)

              # Prepare error reporting data
              description = "Extra "
              text_difference = diff_group.first[1].inspect
            else
              raise "Handle this: #{ diff_group.inspect }"
            end

            # When the PDF text extractor encounters a character that is missing
            # in the font, it returns \uFFFF. This is an issue with the font,
            # and we need to raise an exception.
            if text_diffs.any? { |e| e.index("\uFFFF") }
              raise "Missing character in font: #{ text_diffs.inspect }"
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

          # Remove revision information at the end of the doc
          sanitized_text.gsub!(/\sRevision\sInformation\sDate.+\z/m, '')

          # Clean up an edge case where a space is inserted before a question
          # or exclamation mark, and a newline is inserted after the question/exclamation mark.
          # This occurs a couple times in all files and is best handled here
          # since it's spread over three diffs: -1 '?', 0 ' ', 1 '?\n'
          # We convert "word ?\nWord" => "word?\nWord"
          # We don't touch instances like "word…?… ?". These are legitimate.
          sanitized_text.gsub!(
            /
              (?<!…)  # not preceded by ellipsis
              \s      # a single space
              (\?|\!) # a question or exclamation mark
              \n      # a newline
            /x,
            '\1' + "\n"
          )

          # Remove gap_mark indexes on recording pdfs. Example: `{123}`
          sanitized_text.gsub!(/\{\d+\}/, '')

          # Remove record_marks. Example: `Record id: rid-60281179\n`
          sanitized_text.gsub!(/^Record id: rid-[^\n]+\n/, '')

          # Trim leading and trailing whitespace
          sanitized_text.strip!

          # Convert (NARROW) NO-BREAK SPACE to regular space since the same happens in
          # the process of exporting plain text from content AT.
          sanitized_text.gsub!(/[\u00A0\u202F]/, ' ')

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

          # Convert (NARROW) NO-BREAK SPACE to regular space since the same happens in
          # the process of extracting plain text from PDF.
          sanitized_text.gsub!(/[\u00A0\u202F]/, ' ')

          # Append newline and return
          sanitized_text + "\n"
        end

        # Converts latex_string to plain text.
        # Removes fragments like "\\RtSmCapsEmulation{-0.12em}{" and "}{0em}"
        # @param latex_string [String, nil]
        # @return [String] with latex control sequences removed
        def convert_latex_to_plain_text(latex_string)
          return nil  if latex_string.nil?
          pt = latex_string.dup
          # Replace begin/end tags for environments with spaces
          pt.gsub!(
            /
              \\(begin|end)\{ # begin or end tag followed by opening brace
              [^\}]* # zero or more non closing brace chars for environment name
              \} # followed by closing brace
            /x,
            ' '
          )
          # Remove RtSmCapsEmulation
          pt.gsub!(
            /
              \\RtSmCapsEmulation # latex control sequence
              \{[^\}]*\} # leading kerning argument
              \{ # smallcaps contents start
              ( # capture group 1 to be preserved
                [^\{]* # smallcaps text
              )
              \} # smallcaps contents end
              \{[^\}]*\} # trailing kerning argument
            /x,
            '\1'
          )
          # Remove \\emph NOTE: This has to happen fairly late since we're matching
          # on the closing brace by itself. If there are any nested commands inside
          # the emph, we'd stop at their closing brace.
          pt.gsub!(
            /
              \\emph # latex control sequence
              \{ # emph contents start
              ( # capture group 1 to be preserved
                [^\{]* # emph text
              )
              \} # emph contents end
            /x,
            '\1'
          )
          pt
        end

      end
    end
  end
end
