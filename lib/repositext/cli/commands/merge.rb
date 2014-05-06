class Repositext
  class Cli
    module Merge

    private

      # Merges record_marks from FOLIO XML import into IDML import
      # Uses IDML as authority for text and all tokens except record_marks.
      # If no IDML file is present, uses FOLIO XML as authority for everything.
      def merge_record_marks_from_folio_xml_at_into_idml_at(options)
        input_file_spec_folio_xml = options['input_1'] || 'import_folio_xml_dir/at_files'
        input_file_pattern_folio_xml = config.compute_glob_pattern(input_file_spec_folio_xml)
        import_folio_xml_base_dir = config.base_dir(:import_folio_xml_dir)
        import_idml_base_dir = options['input_2'] || config.base_dir(:import_idml_dir)
        output_base_dir = options['output'] || config.base_dir(:staging_dir)

        $stderr.puts "Merging :record_mark tokens from folio_at into idml_at"
        $stderr.puts '-' * 80
        start_time = Time.now
        total_count = 0
        success_count = 0
        errors_count = 0
        idml_not_present_count = 0
        filtered_text_mismatch_count = 0

        Dir.glob(input_file_pattern_folio_xml).each do |at_folio_file_name|
          if at_folio_file_name !~ /\.at\z/
            $stderr.puts " - Skip #{ at_folio_file_name }"
            next
          end

          total_count += 1

          # prepare paths
          at_idml_file_name = at_folio_file_name.gsub(import_folio_xml_base_dir, import_idml_base_dir).gsub(/folio\.at\z/, 'idml.at')
          output_file_name = at_folio_file_name.gsub(import_folio_xml_base_dir, output_base_dir).gsub(/folio\.at\z/, 'at')

          if File.exists?(at_idml_file_name)
            # IDML file is present
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
          else
            # IDML file is not present,
            # Use Folio import as authority
            FileUtils.mkdir_p(File.dirname(output_file_name))

            # TODO: do we need to do any processing on folio imported?
            at_with_merged_tokens = File.read(at_folio_file_name)

            # write to file
            File.write(output_file_name, at_with_merged_tokens)
            success_count += 1
            idml_not_present_count += 1
            $stderr.puts "   Use #{ at_folio_file_name }"
          end
        end

        $stderr.puts '-' * 80
        $stderr.puts "Finished merging #{ success_count } of #{ total_count } files in #{ Time.now - start_time } seconds."
        $stderr.puts " - IDML files not present: #{ idml_not_present_count }"
      end

      def merge_test(options)
        # dummy method for testing
        puts 'merge_test'
      end

    end
  end
end
