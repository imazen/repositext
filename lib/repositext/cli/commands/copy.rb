class Repositext
  class Cli
    module Copy

    private

      # Copies subtitle_marker csv files to content for subtitle import. Also renames files like so:
      # 59-0125_0547.markers.txt => eng59-0125_0547.subtitle_markers.csv
      def copy_subtitle_marker_csv_files_to_content(options)
        input_file_spec = options['input'] || 'subtitle_tagging_import_dir/txt_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        input_base_dir = config.base_dir(input_base_dir_name)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.markers\.txt\z/,
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

      # Copies subtitle_marker csv files from content to subtitle export.
      # Also renames files like so:
      # eng59-0125_0547.subtitle_markers.csv => 59-0125_0547.markers.txt
      def copy_subtitle_marker_csv_files_to_subtitle_export(options)
        input_file_spec = options['input'] || 'content_dir/csv_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        input_base_dir = config.base_dir(input_base_dir_name)
        output_base_dir = options['output'] || config.base_dir(:subtitle_export_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.subtitle_markers\.csv\z/,
          "Copying subtitle marker CSV files from content_dir to subtitle_export_dir",
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

    end
  end
end
