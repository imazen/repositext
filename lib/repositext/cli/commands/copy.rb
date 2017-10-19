class Repositext
  class Cli
    # This namespace contains methods related to the `copy` command.
    module Copy

    private

      # Copy DOCX imported AT files to content. Also renames files like so:
      # `eng59-0125_0547.docx.at` => `eng59-0125_0547.at`.
      # @param options [Hash]
      def copy_docx_import_to_content(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :docx_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Copying DOCX imported AT files to content",
          options.merge(
            :output_path_lambda => lambda { |input_filename|
              input_filename.gsub(input_base_dir, output_base_dir)
                            .gsub(/\.docx\.at\z/, '.at')
            }
          )
        )
      end

      # Copy HTML imported AT files to content. Also renames files like so:
      # `eng59-0125_0547.html.at` => `eng59-0125_0547.at`.
      # @param options [Hash]
      def copy_html_import_to_content(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :html_import_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Copying HTML imported AT files to content",
          options.merge(
            :output_path_lambda => lambda { |input_filename|
              input_filename.gsub(input_base_dir, output_base_dir)
                            .gsub(/\.html\.at\z/, '.at')
            }
          )
        )
      end

      # Copy PDF export files to distribution dir.
      # Creates distribution dir if it doesn't exist already and deletes any
      # files currently in distribution dir.
      # @param options [Hash]
      def copy_pdf_export_to_distribution(options)
        # Create distribution dir if it doesn't exist yet
        output_base_dir = options['output'] || config.compute_base_dir(:pdf_export_distribution_dir)
        FileUtils.mkdir_p(output_base_dir)

        # Delete all files in distribution dir
        delete_files(
          'base-dir' => output_base_dir,
          'file-selector' => "*",
          'file-extension' => config.compute_file_extension(:pdf_extension),
        )

        # Copy exported files into distribution dir
        input_base_dir = config.compute_base_dir(options['base-dir'] || :pdf_export_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :pdf_extension)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Copying exported PDF files to distribution directory",
          options.merge(
            :output_path_lambda => lambda { |input_filename|
              File.join(output_base_dir, File.basename(input_filename))
            }
          )
        )
      end

      # Copy subtitle_marker csv files to content for subtitle import. Also renames files like so:
      # `59-0125_0547.markers.txt` => `eng59-0125_0547.subtitle_markers.csv`.
      # @param options [Hash]
      # @option options [String] 'base-dir': (required) one of 'subtitle_tagging_import_dir' or 'subtitle_import_dir'
      # @option options [String] 'file-pattern': defaults to 'txt_files', can be custom pattern
      # TODO SPID: This can't be just a copy any more since SPIDS are getting lost.
      def copy_subtitle_marker_csv_files_to_content(options)
        input_base_dir = config.compute_base_dir(options['base-dir'])
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :txt_extension)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'] || /\.markers\.txt\z/,
          "Copying subtitle marker CSV files from subtitle_tagging_import_dir to content_dir",
          options.merge(
            :output_path_lambda => lambda { |input_filename|
              input_filename.gsub(input_base_dir, output_base_dir)
                            .gsub(
                              /\/([^\/\.]+)\.markers\.txt/,
                              '/' + config.setting(:language_code_3_chars) + '\1.subtitle_markers.csv'
                            )
            }
          )
        )
      end

      # Copy subtitle_marker csv files from content to subtitle export.
      # Also renames files like so:
      # `eng59-0125_0547.subtitle_markers.csv` => `59-0125_0547.markers.txt`.
      def copy_subtitle_marker_csv_files_to_subtitle_export(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :csv_extension)
        # grab source marker_csv file from primary repo
        primary_repo_input_base_dir = input_base_dir.sub(
          config.base_dir(:content_type_dir), config.primary_content_type_base_dir
        )
        output_base_dir = options['output'] || config.base_dir(:subtitle_export_dir)
        Repositext::Cli::Utils.copy_files(
          primary_repo_input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'] || /\.subtitle_markers\.csv\z/,
          "Copying subtitle marker CSV files from content_dir to subtitle_export_dir",
          options.merge(
            output_path_lambda: lambda { |input_filename|
              Service::Filename::ConvertStmCsvToStExport.call(
                source_filename: input_filename.sub(
                  primary_repo_input_base_dir,
                  output_base_dir
                )
              )[:result]
            }
          )
        )
      end

    end
  end
end
