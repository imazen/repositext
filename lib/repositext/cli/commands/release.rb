class Repositext
  class Cli
    # This namespace contains methods related to the `release` command.
    module Release

      # Increments (or creates new) public version ids for all files matching
      # file-selector. Raises an error if no file-selector is given.
      # File selector has to be provided either via
      # * --dc option OR
      # * --file-selector option in the form "**/*{<date code>,<date code>}*"
      # Key is that we need a specific list of files and not a pattern that matches
      # a group of files (e.g., just the year)
      def release_increment_pdf_public_version_ids(options)
        if options['skip-erp-api']
          raise("\n\nERP API access is required for this command.\n\n".color(:red))
        end
        # Validate that file-selector is given
        if options['file-selector'].blank? || !options['file-selector'][/\{[^\}]+\}/]
          raise ArgumentError.new(
            "\n\nYou must provide a list of files for this command via --dc or --file-selector (using \"**/*{<date code>,<date code>}*\").\n".color(:red)
          )
        end
        # Compute list of all files matching file-selector
        file_list_pattern = config.compute_glob_pattern(
          options['base-dir'] || :content_dir,
          options['file-selector'],
          options['file-extension'] || :at_extension
        )
        file_list = Dir.glob(file_list_pattern)
        language = content_type.language
        file_pi_ids = file_list.map { |filename|
          RFile::Content.new(
            '_',
            language,
            filename
          ).extract_product_identity_id(false).to_i
        }
        # Request new public version ids for list of files
        erp_response = Services::ErpApi.call(
          config.setting(:erp_api_protocol_and_host),
          ENV['ERP_API_APPID'],
          ENV['ERP_API_NAMEGUID'],
          :increment_pdf_public_version_id,
          {
            languageids: [language.code_3_chars].join(','),
            ids: file_pi_ids.join(','),
            isnew: 1,
          }
        )
        Services::ErpApi.validate_product_identity_ids(erp_response, file_pi_ids)
      end

    end
  end
end
