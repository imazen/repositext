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
        # generate diff index
        $stderr.puts "Generating diff report for record_id and paragraph alignment"
        $stderr.puts '-' * 80
        report_name = 'compare_record_id_and_paragraph_alignment'
        base_dir = config.base_dir('compare_dir')
        compare_content_with_folio_source_glob_pattern = (
          File.join(
            base_dir,
            'content',
            'with_folio_source',
            config.file_pattern('txt_files')
          )
        )
        filename_2_proc = Proc.new { |filename_1|
          filename_1.sub(
            '/content/with_folio_source/',
            '/folio_source/with_content/'
          )
        }
        # Delete existing report
        FileUtils.rm_rf(
          Dir.glob(File.join(base_dir, "#{ report_name }/*"))
        )
        diff_html_files = []
        success_count = 0

        Repositext::Cli::Utils.read_files(
          compare_content_with_folio_source_glob_pattern,
          /\.txt\Z/i,
          filename_2_proc,
          "Reading /compare/content/with_folio_source files",
          options
        ) do |contents_1, filename_1, contents_2, filename_2|
          outcome = Repositext::Compare::RecordIdAndParagraphAlignment.compare(
            contents_1,
            filename_1,
            contents_2,
            filename_2,
            base_dir,
            report_name
          )
          if ![nil, ''].include?(outcome.result[:html_report])
            # write diff_html_doc
            diff_filename = outcome.result[:html_report_filename]
            FileUtils.mkdir_p(File.dirname(diff_filename))
            File.write(diff_filename, outcome.result[:html_report])
            success_count += 1

            diff_html_files << {
              :filename => diff_filename,
              :number_of_diffs => outcome.result[:number_of_diffs],
            }
          end
        end

        # Generate index page
        template_path = File.expand_path(
          "../../../../../templates/html_diff_report_index.html.erb", __FILE__
        )
        @title = 'Compare Record id and paragraph alignment index'
        @diff_html_files = diff_html_files.map { |e|
          filename = e[:filename].gsub(base_dir, '')
          diffs = e[:number_of_diffs].map { |k,v|
            %(<span class="label #{ k }">#{ 1 == v ? '1 record' : " #{ v } records" }</span>)
          }.join(' ')
          %(
            <tr>
              <td>
                <a href="#{ filename }">#{ filename.split('/').last }</a>
              </td>
              <td>#{ diffs }</td>
            </tr>
          )
        }.join
        erb_template = ERB.new(File.read(template_path))
        index_filename = File.join(base_dir, [report_name, '-index', '.html'].join)
        File.write(index_filename, erb_template.result(binding))

        # html_files
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
