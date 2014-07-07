class Repositext
  class Cli
    module Merge

    private

      # Merges record_marks from FOLIO XML import into IDML import
      # Uses IDML as authority for text and all tokens except record_marks.
      # If no IDML file is present, uses FOLIO XML as authority for everything.
      def merge_record_marks_from_folio_xml_at_into_idml_at(options)
        input_folio_base_dir = config.base_dir(:folio_import_dir)
        input_idml_base_dir = config.base_dir(:idml_import_dir)
        input_file_pattern = config.file_pattern(:at_files)
        output_base_dir = config.base_dir(:staging_dir)
        $stderr.puts 'Merging :record_mark tokens from folio_at into idml_at'
        $stderr.puts '-' * 80
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0
        idml_not_present_count = 0
        folio_not_present_count = 0
        filtered_text_mismatch_count = 0


        # First get union of all Folio and Idml files
        folio_files = Dir.glob(File.join(input_folio_base_dir, input_file_pattern))
        idml_files = Dir.glob(File.join(input_idml_base_dir, input_file_pattern))
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

        $stderr.puts '-' * 80
        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts " - Folio files not present: #{ folio_not_present_count }"
        $stderr.puts " - IDML files not present: #{ idml_not_present_count }"
      end

      # Merges subtitle_marks from subtitle_tagging_import into content AT.
      # Uses content AT as authority for text and all tokens except subtitle_marks.
      def merge_subtitle_marks_from_subtitle_tagging_import_into_content_at(options)
        input_file_spec_subtitle_tagging_import = options['input_1'] || 'subtitle_tagging_import_dir/txt_files'
        input_file_pattern_subtitle_tagging_import = config.compute_glob_pattern(input_file_spec_subtitle_tagging_import)
        base_dir_subtitle_tagging_import = config.base_dir(:subtitle_tagging_import_dir)
        base_dir_content = options['input_2'] || config.base_dir(:content_dir)
        base_dir_output = options['output'] || config.base_dir(:content_dir)

        $stderr.puts 'Merging :subtitle_mark tokens from subtitle_tagging_import into content_at'
        $stderr.puts '-' * 80
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0

        Dir.glob(input_file_pattern_subtitle_tagging_import).each do |subtitle_tagging_import_file_name|
          if subtitle_tagging_import_file_name !~ /(?<!markers)\.txt\z/ # don't include .markers.txt files!
            $stderr.puts " - Skip #{ subtitle_tagging_import_file_name }"
            next
          end

          total_count += 1
          # prepare paths
          content_at_file_name = Repositext::Utils::SubtitleTaggingFilenameConverter.convert_from_subtitle_tagging_import_to_repositext(
            subtitle_tagging_import_file_name.gsub(base_dir_subtitle_tagging_import, base_dir_content)
          )
          output_file_name = content_at_file_name

          begin
            outcome = Repositext::Merge::SubtitleMarksFromSubtitleTaggingImportIntoContentAt.merge(
              File.read(subtitle_tagging_import_file_name),
              File.read(content_at_file_name),
            )

            if outcome.success
              # write to file
              at_with_merged_tokens = outcome.result
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_merged_tokens)
              success_count += 1
              $stderr.puts " + Merge :subtitle_marks from #{ subtitle_tagging_import_file_name }"
            else
              errors_count += 1
              $stderr.puts " x Error: #{ subtitle_tagging_import_file_name }: #{ outcome.messages.join }"
            end
          rescue StandardError => e
            errors_count += 1
            $stderr.puts " x Error: #{ subtitle_tagging_import_file_name }: #{ e.class.name } - #{ e.message } - #{ e.backtrace.join("\n") }"
          end
        end

        $stderr.puts '-' * 80
        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
      end

      def merge_test(options)
        # dummy method for testing
        puts 'merge_test'
      end

    end
  end
end
