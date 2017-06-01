class Repositext
  class Validation
    # Validation to run after a subtitle import 1/2.
    class SubtitlePostImport1 < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # Single files

        validate_files(:content_at_files) do |path|
          Validator::KramdownSyntaxAt.new(File.open(path), @logger, @reporter, @options).run
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :content)
            ).run
            Validator::SubtitleMarkSpacing.new(
              File.open(path), @logger, @reporter, @options
            ).run
          else
            # Foreign files
            Validator::SubtitleMarkSequenceSyntax.new(
              File.open(path), @logger, @reporter, @options
            ).run
          end
        end

        # File pairs

        # Validate that subtitle_export from new content_at is identical to
        # subtitle/subtitle_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes subtitle_import filename from content_at filename
        si_filename_proc = lambda { |input_filename, file_specs|
          ca_base_dir = file_specs[:content_at_files].first
          si_base_dir = file_specs[:subtitle_import_files].first
          Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_import(
            input_filename.gsub(ca_base_dir, si_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_filename_proc) do |ca, sti|
          Validator::SubtitleImportConsistency.new(
            [File.open(ca), File.open(sti)],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'post_import')
          ).run
        end

      end

    end
  end
end
