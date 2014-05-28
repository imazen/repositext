class Repositext
  class Cli
    module Copy

    private

      # Moves subtitle_marker csv files to content. Also renames files like so:
      # 59-0125_0547.markers.csv => eng59-0125_0547.subtitle_markers.csv
      def copy_subtitle_marker_csv_files_to_content(options)
        input_file_spec = options['input'] || 'subtitle_tagging_import_dir/csv_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        input_base_dir = config.base_dir(input_base_dir_name)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.copy_files(
          input_base_dir,
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.csv\z/,
          "Copying subtitle marker CSV files from subtitle_tagging_import_dir to content_dir",
          options.merge(
            :output_path_lambda => lambda { |input_filename|
              input_filename.gsub(input_base_dir, output_base_dir)
                            .gsub(
                              /\/([^\/\.]+)\.markers\.csv/,
                              '/' + config.setting(:language_code_3_chars) + '\1.subtitle_markers.csv'
                            )
            }
          )
        )
      end

    end
  end
end
