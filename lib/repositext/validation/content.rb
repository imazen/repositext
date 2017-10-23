# TODO: validate that there are no trailing spaces

class Repositext
  class Validation
    # Validation for content.
    class Content < Validation

      # Specifies validations to run for files in the /content directory
      def run_list

        config = @options['config']
        pi_ids_to_validate = []
        validate_files(:content_at_files) { |content_at_file|
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

        # Single files
        validate_files(:content_at_files) do |content_at_file|
          path = content_at_file.filename # for legacy validators
          config.update_for_file(path.gsub(/\.at\z/, '.data.json'))
          Validator::ContentAtFilesStartWithRecordMark.new(File.open(path), @logger, @reporter, @options).run
          Validator::CorrectLineEndings.new(File.open(path), @logger, @reporter, @options).run
          Validator::EaglesConnectedToParagraph.new(File.open(path), @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(File.open(path), @logger, @reporter, @options).run

          Validator::TitleConsistency.new(
            content_at_file,
            @logger,
            @reporter,
            @options.merge(
              "erp_data" => erp_data,
              "validator_exceptions" => config.setting(:validator_exceptions_title_consistency)
            )
          ).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkSpacing.new(
              File.open(path), @logger, @reporter, @options
            ).run
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :content)
            ).run
          end
        end
        validate_files(:repositext_files) do |repositext_file|
          path = repositext_file.filename # for legacy validators
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
        end

        # File pairs

        # Validate that there are no significant changes to subtitle_mark positions.
        # Define proc that computes subtitle_mark_csv filename from content_at filename
        # TODO: Should we rely on symlinks to STM CSV files instead?
        stm_csv_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_primary_file
                         .corresponding_subtitle_markers_csv_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_proc) do |content_at_file, stm_csv_file|
          # TODO: Update these validators to new RFile based API
          Validator::SubtitleMarkCountsMatch.new(
            [
              File.open(content_at_file.filename),
              File.open(stm_csv_file.filename)
            ],
            @logger,
            @reporter,
            @options
          ).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkNoSignificantChanges.new(
              [
                File.open(content_at_file.filename),
                File.open(stm_csv_file.filename)
              ],
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
