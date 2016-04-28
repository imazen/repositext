class Repositext
  class Validation
    class SubtitlePreImport < Validation

      # Specifies validations to run before subtitle/subtitle_tagging import.
      def run_list

        # Single files

        # Validate that every paragraph in the import file begins with a subtitle_mark
        validate_files(:subtitle_import_files) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
          next  if path.index('markers.') # skip markers files
          if @options['is_primary_content_type']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :import)
            ).run
            Validator::SubtitleMarkNotFollowedBySpace.new(
              File.open(path), @logger, @reporter, @options
            )
          end
        end

        # File pairs

        # TODO: This section iterates over all content_at_files and then tries
        # to find the corresponding subtitle import files. This breaks if the
        # command is used without a file-selector and encounters a content at
        # file for which no corresponding subtitle import file exists.
        # The approach should be the other way around: Start with the subtitle
        # import files and find the corresponding content_at file.

        # Validate that the subtitle/subtitle_tagging import still matches content_at
        # Define proc that computes subtitle/subtitle_tagging import filename from content_at filename
        si_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir = file_specs[:content_at_files].first
          si_base_dir = file_specs[:subtitle_import_files].first
          Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_import(
            input_filename.gsub(ca_base_dir, si_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_file_name_proc) do |ca, sti|
          Validator::SubtitleImportConsistency.new(
            [File.open(ca), File.open(sti)],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'pre_import')
          ).run
        end

      end

    end
  end
end
