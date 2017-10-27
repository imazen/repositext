class Repositext
  class Validation
    # Validation to run after a DOCX import.
    class DocxPostImport < Validation

      # Specifies validations to run related to Docx import.
      def run_list

        # Single files
        validate_files(:imported_repositext_files) do |repositext_file|
          Validator::Utf8Encoding.new(
            File.open(repositext_file.filename), @logger, @reporter, @options
          ).run
        end

        config = @options['config']
        pi_ids_to_validate = []
        validate_files(:imported_at_files) { |content_at_file|
          pi_ids_to_validate << content_at_file.extract_product_identity_id.to_i
        }
        erp_data = Services::ErpApi.call(
          config.setting(:erp_api_protocol_and_host),
          ENV['ERP_API_APPID'],
          ENV['ERP_API_NAMEGUID'],
          :get_titles,
          {
            languageids: [@options['content_type'].language_code_3_chars],
            ids: pi_ids_to_validate.join(',')
          }
        )
        Services::ErpApi.validate_product_identity_ids(erp_data, pi_ids_to_validate)

        validate_files(:imported_at_files) do |content_at_file|
          config.update_for_file(content_at_file.corresponding_data_json_filename)
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            File.open(content_at_file.filename), @logger, @reporter, @options
          ).run
          Validator::ValidTypographicQuotes.new(
            content_at_file, @logger, @reporter, @options
          ).run
          Validator::TitleConsistency.new(
            content_at_file,
            @logger,
            @reporter,
            @options.merge(
              "erp_data" => erp_data,
              "validator_exceptions" => config.setting(:validator_exceptions_title_consistency)
            )
          ).run
          if content_at_file.is_primary?
            Validator::ParagraphNumberSequencing.new(
              File.open(content_at_file.filename), @logger, @reporter, @options
            ).run
          else
            # Check pn alignment with primary, which also implies correct sequencing.
            Validator::DocxImportForeignConsistency.new(
              content_at_file, @logger, @reporter, @options
            ).run
            Validator::ParagraphStyleConsistency.new(
              [content_at_file, content_at_file.corresponding_primary_file],
              @logger,
              @reporter,
              @options
            ).run
          end
        end

      end

    end
  end
end
