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
          outcome = valid_docx_workflow?(@file_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      protected

        # @param docx_file_name [String] absolute path to the docx file
        # @return [Outcome]
        def valid_docx_workflow?(docx_file_name)
          repository = @options['repository']
          language = repository.language
          contents = File.binread(docx_file_name).freeze
          docx_file = Repositext::RFile::Binary.new(
            contents, language, docx_file_name, repository
          )

          errors = []
          warnings = []

          validate_correct_file_name(docx_file.basename, errors, warnings)
          validate_corresponding_content_at_with_subtitles_does_not_exist(docx_file, errors, warnings)
          # validate_correct_template_file_used(docx_file, errors, warnings)
          # validate_document_styles_not_modified(docx_file, errors, warnings)

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
        # @param docx_file [Repositext::RFile]
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
        # @param docx_file [Repositext::RFile]
        # @param errors [Array] collector for errors
        # @param warnings [Array] collector for warnings
        def validate_correct_template_file_used(docx_file, errors, warnings)
          # TBD
        end

        # Make sure translators don’t modify paragraph style definitions
        # (e.g., to automatically make all scripture italic.)
        # They need to apply any text formatting manually (e.g., italic) as
        # character attributes.
        def validate_document_styles_not_modified(docx_file, errors, warnings)
          # TBD
        end

      end
    end
  end
end
