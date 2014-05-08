class Repositext
  class Cli
    module Compare

    private

      def compare_idml_roundtrip
      end

      def compare_test(options)
        # dummy method for testing
        puts 'compare_test'
      end

      # Generates a diff view of folio source vs. /content where record ids
      # and paragraph alignment is analyzed.
      def compare_record_id_and_paragraph_alignment(options)
        # iterate over files to compare
          /folio_import/compare/with_source_record_ids
          # each file-pair
            # compute paragraph level diff, prepare for display
            # generate html file with diff info
            # collect name of file and how many diffs
        # generate diff index
        $stderr.puts "Generating diff report for record_id and paragraph alignment"
        $stderr.puts '-' * 80
        input_file_spec = options['input'] || 'content_dir/at_files'
        paired_filename_proc = Proc.new { |filename|
          filename
        }
        diff_html_docs = []
        success_count = 0

        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(input_file_spec),
          /\.at\Z/i,
          paired_filename_proc,
          "Reading folio at files",
          options
        ) do |contents, filename, paired_contents, paired_filename|
          outcome = Repositext::Diff::RecordIdAndParagraphAlignment.diff(
            contents, filename, paired_contents, paired_filename
          )
          # write diff_html_doc
          diff_filename = outcome.result[:diff_html_doc_filename]
          FileUtils.mkdir_p(File.dirname(diff_filename))
          File.write(diff_filename, outcome[:html_doc])
          success_count += 1

          diff_html_docs << {
            :filename => diff_filename,
            :number_of_diffs => outcome.result[:number_of_diffs],
          }
        end

        # Generate index page
        html_files
        $stderr.puts "-" * 80
        $stderr.puts "Finished generating #{ success_count } diff reports."
      end

      def diff_test(options)
        # dummy method for testing
        puts 'diff_test'
      end

    end

    end
  end
end
