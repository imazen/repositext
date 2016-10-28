class Repositext
  class Cli
    # This namespace contains methods related to the compare command.
    module Compare

    private

      # Override this method stub to compare various Folio
      # related files, e.g., after Folio XML import.
      def compare_folio(options)
      end

      # Override this method stub to compare various IDML
      # related files, e.g., after IDML import.
      def compare_idml(options)
      end

      # Generates a diff view of folio source vs. /content where record ids
      # and paragraph alignment are analyzed.
      def compare_record_id_and_paragraph_alignment(options)
        $stderr.puts ''
        $stderr.puts '-' * 80
        $stderr.puts "Generating diff report for record_id and paragraph alignment"
        report_name = 'compare_record_id_and_paragraph_alignment'
        base_dir = config.compute_base_dir(options['base-dir'] || :compare_dir)

        comparer = Repositext::Compare::FolioSourceWithContent.new

        # Prepare compare_files for folio source
        # **************************************
        input_base_dir = File.join(
          config.compute_base_dir(options['base-dir'] || :compare_dir),
          'folio_source/raw_plaintext'
        ) + '/'
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :txt_extension)
        output_base_dir = File.join(
          options['output'] || config.base_dir(:compare_dir),
          'folio_source/with_content'
        ) + '/'
        output_path_lambda = lambda { |input_filename, _output_file_attrs|
          input_filename.gsub(input_base_dir, output_base_dir)
                        .gsub(/\.folio\.txt\z/, '.txt')
        }
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting compare files for folio source",
          options.merge(:output_path_lambda => output_path_lambda)
        ) do |contents, filename|
          outcome = comparer.prepare_compare_file_for_folio_source(contents, filename)
          [outcome]
        end

        # Prepare compare_files for content at
        # ************************************
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = File.join(
          options['output'] || config.base_dir(:compare_dir),
          'content/with_folio_source'
        ) + '/'
        output_path_lambda = lambda { |input_filename, _output_file_attrs|
          input_filename.gsub(input_base_dir, output_base_dir)
                        .gsub(/\.at\z/, '.txt')
        }
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting compare files for content",
          options.merge(:output_path_lambda => output_path_lambda)
        ) do |contents, filename|
          outcome = comparer.prepare_compare_file_for_content(contents, filename)
          [outcome]
        end

        # Generate HTML report
        # ************************************
        compare_content_with_folio_source_glob_pattern = (
          File.join(
            base_dir,
            'content',
            'with_folio_source',
            [
              config.compute_file_selector(options['file-selector'] || :all_files),
              config.compute_file_extension(options['file-extension'] || :txt_extension)
            ].join
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
        confidence_html_files = []
        success_count = 0

        Repositext::Cli::Utils.read_files(
          compare_content_with_folio_source_glob_pattern,
          options['file_filter'],
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
          # write html report for file
          diff_filename = outcome.result[:html_report_filename]
          FileUtils.mkdir_p(File.dirname(diff_filename))
          File.write(diff_filename, outcome.result[:html_report])
          $stderr.puts "   - Wrote confidences to #{ diff_filename }"
          success_count += 1

          confidence_html_files << {
            :filename => diff_filename,
            :number_of_confidence_levels => outcome.result[:number_of_confidence_levels],
          }
        end

        # Generate index page
        template_path = File.expand_path(
          "../../../../../templates/html_diff_report_index.html.erb", __FILE__
        )
        @title = 'Compare Record id and paragraph alignment index'
        @number_of_files_with_low_confidence = confidence_html_files.count { |e|
          # has at least one entry under key 'label-warning' or 'label-danger'
          (["label-warning", "label-danger"] & e[:number_of_confidence_levels].keys).any?
        }
        @confidence_html_files = confidence_html_files.map { |e|
          filename = e[:filename].gsub(base_dir, '')
          confidences = e[:number_of_confidence_levels].map { |k,v|
            %(<span class="label #{ k }">#{ 1 == v ? '1 record' : " #{ v } records" }</span>)
          }.join(' ')
          %(
            <tr>
              <td>
                <a href="#{ filename }">#{ filename.split('/').last }</a>
              </td>
              <td>#{ confidences }</td>
            </tr>
          )
        }.join
        erb_template = ERB.new(File.read(template_path))
        index_filename = File.join(base_dir, [report_name, '-index', '.html'].join)
        File.write(index_filename, erb_template.result(binding))

        $stderr.puts "Finished generating #{ success_count } diff reports."
        $stderr.puts "-" * 80
      end

      def compare_test(options)
        # dummy method for testing
        puts 'compare_test'
      end

    end
  end
end
