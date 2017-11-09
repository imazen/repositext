class Repositext
  class Validation
    class Validator

      # Validates workflow related aspects of DOCX import.
      class DocxImportWorkflow < Validator

        class InvalidFileNameError < ::StandardError; end
        class ContentAtFileWithSubtitlesExistsError < ::StandardError; end

        def self.valid_file_name_regex
          /
            [[:alpha:]]{3} # language code 3 chars
            (
              \d{2}-\d{4}[[:alpha:]]?
              | # or
              [a-z_\-\d]+
            )
            _\d{4} # product identity id
            \.docx # file extension
          /x
        end

        # Runs all validations for self
        def run
          docx_file = @file_to_validate
          outcome = valid_docx_workflow?(docx_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param docx_file [RFile::Docx] the DOCX file to be imported
        # @return [Outcome]
        def valid_docx_workflow?(docx_file)
          errors = []
          warnings = []

          validate_correct_file_name(docx_file.basename, errors, warnings)
          validate_corresponding_content_at_with_subtitles_does_not_exist(docx_file, errors, warnings)
          # validate_correct_template_file_used(docx_file, errors, warnings)
          validate_document_styles_not_modified(
            docx_file.extract_docx_styles_xml,
            errors,
            warnings
          )

          Outcome.new(errors.empty?, nil, [], errors, warnings)
        end

        # Check that docx file has a correct filename
        # Abort import if it doesn't.
        # @param docx_file_name [String] just the base name
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        def validate_correct_file_name(docx_file_name, errors, warnings)
          if(docx_file_name !~ self.class.valid_file_name_regex)
            # We need to terminate an import if we get here so we raise an exception.
            raise InvalidFileNameError.new(
              [
                '',
                '',
                'The DOCX filename is not valid.',
                'It needs to look like one of these examples: "eng56-0101_0297.docx" or "norcab_01_-_title_1386.docx"',
                "This is what it looked like instead: #{ docx_file_name }",
                '',
                '',
              ].join("\n")
            )
          end
        end

        # Check if corresponding content AT file exists and has subtitles.
        # Abort import if this is the case.
        # @param docx_file [Repositext::RFile::Docx]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        def validate_corresponding_content_at_with_subtitles_does_not_exist(docx_file, errors, warnings)
          if(
            ccatf = docx_file.corresponding_content_at_file and
            ccatf.has_subtitles?
          )
            # We need to terminate an import if we get here so we raise an exception.
            raise ContentAtFileWithSubtitlesExistsError.new(
              [
                '',
                '',
                'The corresponding content AT file already exists and has subtitles. ',
                'Import cannot proceed unless you delete it: ',
                ccatf.filename,
                '',
                '',
              ].join("\n")
            )
          end
        end

        # Make sure file name is valid as confirmation that translator used the
        # corrected template.
        # @param docx_file [Repositext::RFile::Docx]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        def validate_correct_template_file_used(docx_file, errors, warnings)
          # TBD
        end

        # Make sure translators don’t modify paragraph style definitions
        # (e.g., to automatically make all scripture italic.)
        # They need to apply any text formatting manually (e.g., italic) as
        # character attributes.
        # @param styles_xml_contents [String] the contents of word/styles.xml as string
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        def validate_document_styles_not_modified(styles_xml_contents, errors, warnings)
          xml_styles = Nokogiri::XML(styles_xml_contents) { |config| config.noblanks }
          xml_styles.xpath('//w:styles//w:style').each { |style_xn|
            style_id = style_xn['w:styleId']
            if (expected_style_attrs = expected_styles[style_id])
              # We check attrs for this style_id

              error_type = 'Unexpected modification of document styles'

              # Check basedOn
              exp_bo = expected_style_attrs[:basedOn]
              if(
                # We expect basedOn to be present
                exp_bo &&
                (
                  (act_bo_xn = style_xn.at_xpath('./w:basedOn')).nil? ||
                  (act_bo = act_bo_xn['w:val']) != exp_bo
                )
              ) || (
                # We expect basedOn to be absent
                !exp_bo &&
                (act_bo_xn = style_xn.at_xpath('./w:basedOn')) &&
                (act_bo = act_bo_xn['w:val'].to_s) != ''
              )
                errors << Reportable.error(
                  [@file_to_validate],
                  [
                    error_type,
                    "Style: #{ style_id }, expected basedOn to be #{ exp_bo.inspect }, got #{ act_bo.inspect }"
                  ]
                )
              end

              # Check pPr (paragraph styles)
              exp_ppr = expected_style_attrs[:pPr]
              act_ppr_xn = style_xn.at_xpath('./w:pPr')
              act_ppr = act_ppr_xn ? act_ppr_xn.children.map { |e| e.name }.sort : []
              if act_ppr != exp_ppr
                errors << Reportable.error(
                  [@file_to_validate],
                  [
                    error_type,
                    "Style: #{ style_id }, expected pPr to contain the following attrs: #{ exp_ppr.inspect }, got #{ act_ppr.inspect }"
                  ]
                )
              end

              # Check rPr (text run styles)
              exp_rpr = expected_style_attrs[:rPr]
              act_rpr_xn = style_xn.at_xpath('./w:rPr')
              act_rpr = act_rpr_xn ? act_rpr_xn.children.map { |e| e.name }.sort : []
              if act_rpr != exp_rpr
                errors << Reportable.error(
                  [@file_to_validate],
                  [
                    error_type,
                    "Style: #{ style_id }, expected rPr to contain the following attrs: #{ exp_rpr.inspect }, got #{ act_rpr.inspect }"
                  ]
                )
              end
            end
          }
        end

        # Returns a hash with expected attributes for the styles we validate.
        # The document styles must have exactly the expected attributes, no
        # more and no less. This is to ensure that text formatting like italics
        # and bold is applied via character attributes and not as part of the
        # paragraph style.
        # This implementation matches the following two styles:
        #     <w:style w:default="1" w:styleId="Normal" w:type="paragraph">
        #       <w:name w:val="Normal"/>
        #       <w:rsid w:val="0007621A"/>
        #       <w:pPr>
        #         <w:tabs>
        #           <w:tab w:pos="360" w:val="left"/>
        #         </w:tabs>
        #         <w:spacing w:after="0" w:before="60" w:line="240" w:lineRule="auto"/>
        #         <w:jc w:val="both"/>
        #       </w:pPr>
        #       <w:rPr>
        #         <w:rFonts w:ascii="V-Excelsior LT Std" w:hAnsi="V-Excelsior LT Std"/>
        #         <w:color w:themeColor="text1" w:val="000000"/>
        #         <w:sz w:val="20"/>
        #       </w:rPr>
        #     </w:style>
        #     <w:style w:styleId="Heading1" w:type="paragraph">
        #       <w:name w:val="heading 1"/>
        #       <w:basedOn w:val="Normal"/>
        #       <w:next w:val="Normal"/>
        #       <w:link w:val="Heading1Char"/>
        #       <w:uiPriority w:val="9"/>
        #       <w:rsid w:val="00A06EAA"/>
        #       <w:pPr>
        #         <w:keepNext/>
        #         <w:keepLines/>
        #         <w:spacing w:before="480"/>
        #         <w:outlineLvl w:val="0"/>
        #       </w:pPr>
        #       <w:rPr>
        #         <w:rFonts w:asciiTheme="majorHAnsi" w:cstheme="majorBidi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi"/>
        #         <w:b/>
        #         <w:bCs/>
        #         <w:color w:themeColor="accent1" w:themeShade="B5" w:val="345A8A"/>
        #         <w:sz w:val="32"/>
        #         <w:szCs w:val="32"/>
        #       </w:rPr>
        #     </w:style>
        # @return [Hash] with style ids as keys
        def expected_styles
          # Important: Sort attrs under pPr and rPr alphabetically!
          {
            "Normal" => {
              basedOn: nil,
              pPr: %w[jc spacing tabs],
              rPr: %w[color rFonts sz],
            },
            "Heading1" => {
              basedOn: "Normal",
              pPr: %w[keepLines keepNext outlineLvl spacing],
              rPr: %w[b bCs color rFonts sz szCs],
            },
          }
        end

      end
    end
  end
end
