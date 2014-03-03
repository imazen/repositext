class Repositext
  class Cli
    module Merge

    private

      # Merges record_marks from FOLIO XML import into IDML import
      # Uses IDML as authority for text and all tokens except record_marks.
      # If no IDML file is present, uses FOLIO XML as authority for everything.
      def merge_record_marks_from_folio_xml_at_into_idml_at(options)
        input_file_spec_folio_xml = options[:input_1] || 'import_folio_xml_dir.at_files'
        input_file_pattern_folio_xml = config.compute_glob_pattern(input_file_spec_folio_xml)
        import_folio_xml_base_dir = config.base_dir(:import_folio_xml_dir)
        import_idml_base_dir = options[:input_2] || config.base_dir(:import_idml_dir)
        output_base_dir = options[:output] || config.base_dir(:staging_dir)

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

              case 'use_old'
              when 'use_new'
                # Get txt from at_idml
                at_idml_txt_only = Suspension::TokenRemover.new(
                  at_idml,
                  Suspension::REPOSITEXT_TOKENS
                ).remove

                # Remove all tokens but :record_mark from at_folio
                # Need to retain both :record_mark as well as the connected :ial_span.
                # Otherwise only '^^^' would be left (without the IAL)
                at_folio_with_record_marks_only = Suspension::TokenRemover.new(
                  at_folio,
                  Suspension::REPOSITEXT_TOKENS.find_all { |e| ![:ial_span, :record_mark].include?(e.name) }
                ).remove

                # Replay idml text changes on at_folio_with_record_marks_only
                at_with_record_marks_only = Suspension::TextReplayer.new(
                  at_idml_txt_only,
                  at_folio_with_record_marks_only,
                  Suspension::REPOSITEXT_TOKENS
                ).replay

                # Remove :record_mark tokens from at_idml (there shouldn't be any in there, just to be sure)
                at_idml_without_record_marks = Suspension::TokenRemover.new(
                  at_idml,
                  Suspension::REPOSITEXT_TOKENS.find_all { |e| :record_mark == e.name }
                ).remove

                # Add :record_marks to text and all other tokens.
                at_with_all_tokens = Suspension::TokenReplacer.new(
                  at_with_record_marks_only,
                  at_idml_without_record_marks
                ).replace([:record_mark])
              when 'use_old'
                # Get plain text from at_idml
                at_without_tokens = Suspension::TokenRemover.new(
                  at_idml,
                  Suspension::REPOSITEXT_TOKENS
                ).remove

                # Add :record_mark tokens only to at_idml plain text
                at_with_record_marks_only = Suspension::TextReplayer.new(
                  at_without_tokens,
                  at_folio,
                  Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
                ).replay

                # Remove :record_mark tokens from at_idml
                at_without_record_marks = Suspension::TokenRemover.new(
                  at_idml,
                  Suspension::REPOSITEXT_TOKENS.find_all { |e| [:record_mark].include?(e.name) }
                ).remove

                # Add :record_marks to text and all other tokens.
                at_with_all_tokens = Suspension::TokenReplacer.new(
                  at_with_record_marks_only,
                  at_without_record_marks
                ).replace([:record_mark])
              end

              # write to file
              FileUtils.mkdir_p(File.dirname(output_file_name))
              File.write(output_file_name, at_with_all_tokens)
              success_count += 1
              $stderr.puts " + Merge rids from #{ at_folio_file_name }"
            rescue Exception => e
              errors_count += 1
              puts " x Error in #{ at_folio_file_name }: #{ e.class.to_s }, #{ e.message }"
            end
          else
            # IDML file is not present,
            # Use Folio import as authority
            FileUtils.mkdir_p(File.dirname(output_file_name))

            # TODO: do we need to do any processing on folio imported?
            at_with_all_tokens = File.read(at_folio_file_name)

            # write to file
            File.write(output_file_name, at_with_all_tokens)
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
