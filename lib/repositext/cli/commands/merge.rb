class Repositext
  class Cli
    module Merge

    private

      # Merges accepted corrections for specially formatted files into content AT.
      # This is done in two steps:
      #  1. Apply all corrections that can be done automatically (based on exact text matches)
      #  2. Apply manual corrections where no or multiple extact matches are found.
      # We have to do it in two steps so that when we open the file in the editor
      # for manual changes, all auto corrections are already applied to the file
      # and they don't overwrite any manual corrections prior to when the script
      # stores auto corrections to disk.
      def merge_accepted_corrections_into_content_at(options)
        accepted_corrections_base_dir = config.compute_base_dir(
          options['base-dir'] ||
          options['base-dir-1'] ||
          :accepted_corrections_dir
        )
        accepted_corrections_glob_pattern = config.compute_glob_pattern(
          accepted_corrections_base_dir,
          options['file-selector'] || :all_files,
          options['file-extension'] || :txt_extension
        )
        content_base_dir = config.compute_base_dir(options['base-dir-2'] || :content_dir)

        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging accepted corrections into content_at'
        start_time = Time.now
        total_count = 0
        auto_success_count = 0
        manual_success_count = 0
        errors_count = 0

        Dir.glob(accepted_corrections_glob_pattern).each do |accepted_corrections_file_name|
          if accepted_corrections_file_name !~ /\.accepted_corrections\.txt\z/
            next
          end
          total_count += 1
          # prepare paths
          content_at_file_name = accepted_corrections_file_name.gsub(
            accepted_corrections_base_dir,
            content_base_dir
          ).gsub(
            /\.accepted_corrections\.txt\z/, '.at'
          )
          output_file_name = content_at_file_name

          begin
            # First apply all corrections that can be done automatically
            outcome = Repositext::Merge::AcceptedCorrectionsIntoContentAt.merge_auto(
              File.read(accepted_corrections_file_name),
              File.read(content_at_file_name),
              content_at_file_name,
            )

            if outcome.success
              # write to file
              at_with_accepted_corrections = outcome.result
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_accepted_corrections)
              auto_success_count += 1
              $stderr.puts " + Auto-merged accepted corrections from #{ accepted_corrections_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ accepted_corrections_file_name }: #{ outcome.messages.join }"
            end

            # Second apply manual corrections.
            outcome = Repositext::Merge::AcceptedCorrectionsIntoContentAt.merge_manually(
              File.read(accepted_corrections_file_name),
              File.read(content_at_file_name),
              content_at_file_name,
            )

            if outcome.success
              # Nothing needs to be written to file. This has already been done
              # manually in the editor.
              manual_success_count += 1
              $stderr.puts " + Manually merged accepted corrections from #{ accepted_corrections_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ accepted_corrections_file_name }: #{ outcome.messages.join }"
            end
          rescue StandardError => e
            errors_count += 1
            $stderr.puts " x Error: #{ accepted_corrections_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
          end
        end

        $stderr.puts "Finished merging #{ total_count } files in #{ Time.now - start_time } seconds:"
        $stderr.puts " - Auto-merges: #{ auto_success_count } files."
        $stderr.puts " - Manual merges: #{ manual_success_count } files."
        $stderr.puts '-' * 80
      end

      # Merges gap_mark_tagging_import into content AT.
      # Uses content AT as authority for text.
      def merge_gap_mark_tagging_import_into_content_at(options)
        gap_mark_tagging_import_base_dir = config.compute_base_dir(
          options['base-dir'] || options['base-dir-1'] || :gap_mark_tagging_import_dir
        )
        gap_mark_tagging_import_glob_pattern = config.compute_glob_pattern(
          gap_mark_tagging_import_base_dir,
          options['file-selector'] || :all_files,
          options['file-extension'] || :txt_extension
        )
        content_base_dir = config.compute_base_dir(
          options['base-dir-2'] || :content_dir
        )
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging :gap_mark tokens from gap_mark_tagging_import into content_at'
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0

        Dir.glob(gap_mark_tagging_import_glob_pattern).each do |gap_mark_tagging_import_file_name|
          if gap_mark_tagging_import_file_name !~ /\.gap_mark_tagging\.txt\z/
            next
          end

          total_count += 1
          # prepare paths
          content_at_file_name = gap_mark_tagging_import_file_name.gsub(
            gap_mark_tagging_import_base_dir, content_base_dir
          ).gsub(
            /\.gap_mark_tagging\.txt\z/, '.at'
          )
          output_file_name = content_at_file_name

          begin
            outcome = Repositext::Merge::GapMarkTaggingImportIntoContentAt.merge(
              File.read(gap_mark_tagging_import_file_name),
              File.read(content_at_file_name),
            )

            if outcome.success
              # write to file
              at_with_merged_tokens = outcome.result
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_merged_tokens)
              success_count += 1
              $stderr.puts " + Merge :gap_marks from #{ gap_mark_tagging_import_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ gap_mark_tagging_import_file_name }: #{ outcome.messages.join }"
            end
          rescue StandardError => e
            errors_count += 1
            $stderr.puts " x Error: #{ gap_mark_tagging_import_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
          end
        end

        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts '-' * 80
      end


      # Merges record_marks from FOLIO XML import into IDML import
      # Uses IDML as authority for text and all tokens except record_marks.
      # If no IDML file is present, uses FOLIO XML as authority for everything.
      def merge_record_marks_from_folio_xml_at_into_idml_at(options)
        input_folio_base_dir = config.compute_base_dir(
          options['base-dir'] || options['base-dir-1'] || :folio_import_dir
        )
        input_idml_base_dir = config.compute_base_dir(options['base-dir-2'] || :idml_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = config.base_dir(:staging_dir)
        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging :record_mark tokens from folio_at into idml_at'
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0
        idml_not_present_count = 0
        folio_not_present_count = 0
        filtered_text_mismatch_count = 0

        # First get union of all Folio and Idml files
        folio_files = Dir.glob([input_folio_base_dir, input_file_selector, input_file_extension].join)
        idml_files = Dir.glob([input_idml_base_dir, input_file_selector, input_file_extension].join)
        all_output_files = (folio_files + idml_files).map { |e|
          # process folio files
          e = e.gsub(input_folio_base_dir, output_base_dir)
               .gsub(/\.folio\.at\z/, '.at')
          # process idml files
          e = e.gsub(input_idml_base_dir, output_base_dir)
               .gsub(/\.idml\.at\z/, '.at')
        }.uniq.sort
        all_output_files.each do |output_file_name|
          if output_file_name !~ /\.at\z/
            $stderr.puts " - Skip #{ output_file_name }"
            next
          end

          total_count += 1

          # prepare paths
          at_folio_file_name = output_file_name.gsub(output_base_dir, input_folio_base_dir).gsub(/\.at\z/, '.folio.at')
          at_idml_file_name = output_file_name.gsub(output_base_dir, input_idml_base_dir).gsub(/\.at\z/, '.idml.at')

          if File.exists?(at_folio_file_name) && File.exists?(at_idml_file_name)
            # Both files are present, merge tokens
            begin
              at_folio = File.read(at_folio_file_name)
              at_idml = File.read(at_idml_file_name)
              at_with_merged_tokens = Repositext::Merge::RecordMarksFromFolioXmlAtIntoIdmlAt.merge(
                at_folio, at_idml
              )
              # write to file
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_merged_tokens)
              success_count += 1
              $stderr.puts " + Merge rids from #{ at_folio_file_name }"
            rescue StandardError => e
              errors_count += 1
              $stderr.puts " x Error: #{ at_folio_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
            end
          elsif File.exists?(at_folio_file_name)
            # IDML file is not present, use Folio import as authority
            FileUtils.mkdir_p(File.dirname(output_file_name))
            at_with_merged_tokens = File.read(at_folio_file_name)
            # write to file
            File.write(output_file_name, at_with_merged_tokens)
            success_count += 1
            idml_not_present_count += 1
            $stderr.puts "   Use #{ at_folio_file_name }"
          elsif File.exists?(at_idml_file_name)
            # Folio file is not present, use Idml import as authority
            FileUtils.mkdir_p(File.dirname(output_file_name))
            at_with_merged_tokens = File.read(at_idml_file_name)
            # write to file
            File.write(output_file_name, at_with_merged_tokens)
            success_count += 1
            folio_not_present_count += 1
            $stderr.puts "   Use #{ at_idml_file_name }"
          else
            raise "Could find neither Folio nor IDML file! (#{ output_file_name })"
          end
        end

        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts " - Folio files not present: #{ folio_not_present_count }"
        $stderr.puts " - IDML files not present: #{ idml_not_present_count }"
        $stderr.puts '-' * 80
      end

      # Merges subtitle_marks from subtitle_import into content AT.
      # Uses content AT as authority for text and all tokens except subtitle_marks.
      def merge_subtitle_marks_from_subtitle_import_into_content_at(options)
        subtitle_import_base_dir = config.compute_base_dir(
          options['base-dir'] || options['base-dir-1'] || :subtitle_import_dir
        )
        subtitle_import_glob_pattern = config.compute_glob_pattern(
          subtitle_import_base_dir,
          options['file-selector'] || :all_files,
          options['file-extension'] || :txt_extension
        )
        content_base_dir = config.compute_base_dir(options['base-dir-2'] || :content_dir)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging :subtitle_mark tokens from subtitle_import into content_at'
        merge_subtitle_marks_from_subtitle_shared_into_content_at(
          subtitle_import_glob_pattern,
          subtitle_import_base_dir,
          content_base_dir,
          options
        )
      end

      # Merges subtitle_marks from subtitle_tagging_import into content AT.
      # Uses content AT as authority for text and all tokens except subtitle_marks.
      def merge_subtitle_marks_from_subtitle_tagging_import_into_content_at(options)
        subtitle_tagging_import_base_dir = config.compute_base_dir(
          options['base-dir'] || options['base-dir-1'] || :subtitle_tagging_import_dir
        )
        subtitle_tagging_import_glob_pattern = config.compute_glob_pattern(
          subtitle_tagging_import_base_dir,
          options['file-selector'] || :all_files,
          options['file-extension'] || :txt_extension
        )
        content_base_dir = config.compute_base_dir(options['base-dir-2'] || :content_dir)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging :subtitle_mark tokens from subtitle_tagging_import into content_at'
        merge_subtitle_marks_from_subtitle_shared_into_content_at(
          subtitle_tagging_import_glob_pattern,
          subtitle_tagging_import_base_dir,
          content_base_dir,
          options
        )
      end

      # Merges titles from folio roundtrip compare txt files into content AT
      # to get correct spelling.
      def merge_titles_from_folio_roundtrip_compare_into_folio_import(options)
        folio_roundtrip_compare_base_dir = File.join(
          config.compute_base_dir(
            options['base-dir'] || options['base-dir-1'] || :compare_dir
          ),
          'folio_source/with_folio_import'
        )
        folio_import_base_dir = config.compute_base_dir(options['base-dir-2'] || :folio_import_dir)
        markers_file_regex = /(?<!markers)\.txt\z/

        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Merging titles from folio roundtrip compare into content_at'
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0

        Dir.glob(
          [
            folio_roundtrip_compare_base_dir,
            config.compute_file_selector(options['file-selector'] || :all_files),
            config.compute_file_extension(options['file-extension'] || :txt_extension)
          ].join
        ).each do |folio_roundtrip_compare_file_name|
          total_count += 1
          # prepare paths
          content_at_file_name = folio_roundtrip_compare_file_name.gsub(
            folio_roundtrip_compare_base_dir, # update path
            folio_import_base_dir
          ).gsub(
            /\/+/, '/' # normalize runs of slashes resulting from different directory depths
          ).gsub(
            /\.txt\z/, '.folio.at' # replace file extension
          )
          output_file_name = content_at_file_name
          begin
            outcome = Repositext::Merge::TitlesFromFolioRoundtripCompareIntoContentAt.merge(
              File.read(folio_roundtrip_compare_file_name),
              File.read(content_at_file_name),
            )

            if outcome.success
              # write to file
              at_with_merged_title = outcome.result
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_merged_title)
              success_count += 1
              $stderr.puts " + Merge title from #{ folio_roundtrip_compare_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ folio_roundtrip_compare_file_name }: #{ outcome.messages.join }"
            end
          rescue StandardError => e
            errors_count += 1
            $stderr.puts " x Error: #{ folio_roundtrip_compare_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
          end
        end

        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts '-' * 80
      end

      # Uses either idml_imported (preference) or folio_imported (fallback) at for content.
      # NOTE: this duplicates a lot of code from merge_record_marks_from_folio_xml_at_into_idml_at
      def merge_use_idml_or_folio(options)
        input_folio_base_dir = config.compute_base_dir(
          options['base-dir'] || options['base-dir-1'] || :folio_import_dir
        )
        input_idml_base_dir = config.compute_base_dir(
          options['base-dir-2'] || :idml_import_dir
        )
        input_file_selector = config.compute_file_selector(
          options['file-selector'] || :all_files
        )
        input_file_extension = config.compute_file_extension(
          options['file-extension'] || :at_extension
        )
        output_base_dir = config.base_dir(:staging_dir)
        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts 'Using either idml_at or folio_at for content_at'
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0
        idml_used_count = 0
        folio_used_count = 0

        # TODO: refactor this method to use Cli::Utils so that the changed-only flag works

        # First get union of all Folio and Idml files
        folio_files = Dir.glob([input_folio_base_dir, input_file_selector, input_file_extension].join)
        idml_files = Dir.glob([input_idml_base_dir, input_file_selector, input_file_extension].join)
        all_output_files = (folio_files + idml_files).map { |e|
          # process folio files
          e = e.gsub(input_folio_base_dir, output_base_dir)
               .gsub(/\.folio\.at\z/, '.at')
          # process idml files
          e = e.gsub(input_idml_base_dir, output_base_dir)
               .gsub(/\.idml\.at\z/, '.at')
        }.uniq.sort
        all_output_files.each do |output_file_name|
          if output_file_name !~ /\.at\z/
            $stderr.puts " - Skip #{ output_file_name }"
            next
          end

          total_count += 1

          # prepare paths
          at_folio_file_name = output_file_name.gsub(output_base_dir, input_folio_base_dir).gsub(/\.at\z/, '.folio.at')
          at_idml_file_name = output_file_name.gsub(output_base_dir, input_idml_base_dir).gsub(/\.at\z/, '.idml.at')

          if File.exists?(at_idml_file_name)
            # Idml is present, use it
            FileUtils.mkdir_p(File.dirname(output_file_name))
            idml_at = File.read(at_idml_file_name)
            # write to file
            File.write(output_file_name, idml_at)
            success_count += 1
            idml_used_count += 1
            $stderr.puts "   Use #{ at_idml_file_name }"
          elsif File.exists?(at_folio_file_name)
            # IDML file is not present, bt folio is, use it
            FileUtils.mkdir_p(File.dirname(output_file_name))
            folio_at = File.read(at_folio_file_name)
            # write to file
            File.write(output_file_name, folio_at)
            success_count += 1
            folio_used_count += 1
            $stderr.puts "   Use #{ at_folio_file_name }"
          else
            raise "Could find neither Folio nor IDML file! (#{ output_file_name })"
          end
        end

        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts " - IDML files used: #{ idml_used_count }"
        $stderr.puts " - Folio files used: #{ folio_used_count }"
        $stderr.puts '-' * 80
      end

      def merge_test(options)
        # dummy method for testing
        puts 'merge_test'
      end

    protected

      # @param input_file_pattern_subtitle_import [String] the Dir.glob pattern that describes the input files
      # @param subtitle_import_base_dir [String] the base dir for the import files
      # @param content_base_dir [String] the base dir for the content files
      # @param options [Hash]
      def merge_subtitle_marks_from_subtitle_shared_into_content_at(
        input_file_pattern_subtitle_import,
        subtitle_import_base_dir,
        content_base_dir,
        options
      )
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0

        Dir.glob(input_file_pattern_subtitle_import).each do |subtitle_import_file_name|
          if subtitle_import_file_name =~ /\.markers\.txt\z/
            # don't include markers files!
            $stderr.puts " - Skip #{ subtitle_import_file_name }"
            next
          end

          total_count += 1
          # prepare paths
          content_at_file_name = Repositext::Utils::SubtitleFilenameConverter.convert_from_subtitle_import_to_repositext(
            subtitle_import_file_name.gsub(subtitle_import_base_dir, content_base_dir)
          )
          output_file_name = content_at_file_name

          begin
            outcome = Repositext::Merge::SubtitleMarksFromSubtitleImportIntoContentAt.merge(
              File.read(subtitle_import_file_name),
              File.read(content_at_file_name),
            )

            if outcome.success
              # write to file
              at_with_merged_tokens = outcome.result
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_merged_tokens)
              success_count += 1
              $stderr.puts " + Merge :subtitle_marks from #{ subtitle_import_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ subtitle_import_file_name }: #{ outcome.messages.join }"
            end
          rescue StandardError => e
            errors_count += 1
            $stderr.puts " x Error: #{ subtitle_import_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
          end
        end

        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts '-' * 80
      end

    end
  end
end
