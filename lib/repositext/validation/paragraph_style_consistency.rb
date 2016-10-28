class Repositext
  class Validation
    # Validation to make sure that two files' paragraphs are consistent.
    class ParagraphStyleConsistency < Validation

      # Specifies validations to run for paragraph style consistency between
      # primary and foreign files.
      def run_list

        # File pairs

        # Validate that paragraph styles between foreign and corresponding
        # primary file are consistent.
        corresponding_primary_file_name_proc = lambda { |input_filename, file_specs|
          Repositext::Utils::CorrespondingPrimaryFileFinder.find(
            filename: input_filename,
            language_code_3_chars: @options['primary_content_type_transform_params'][:language_code_3_chars],
            content_type_dir: @options['primary_content_type_transform_params'][:content_type_dir],
            relative_path_to_primary_content_type: @options['primary_content_type_transform_params'][:relative_path_to_primary_content_type],
            primary_repo_lang_code: @options['primary_content_type_transform_params'][:primary_repo_lang_code]
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, corresponding_primary_file_name_proc) do |ca, cpf|
          # skip if corresponding primary file doesn't exist
          next  if !File.exists?(cpf)
          Validator::ParagraphStyleConsistency.new(
            [File.open(ca), File.open(cpf)], @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
