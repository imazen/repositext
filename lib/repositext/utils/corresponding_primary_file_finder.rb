# TODO: Delete this once all code is migrated to Repositext::RFile
class Repositext
  class Utils
    class CorrespondingPrimaryFileFinder

      # Finds a foreign file's corresponding primary file
      #
      # @param params [Hash] a hash with the following keys:
      #     filename: the foreign file's filename (complete absolute path)
      #     language_code_3_chars: the foreign file's language code from config.setting(:language_code_3_chars)
      #     content_type_dir: the foreign file's Rtfile path from config.base_dir(:content_type_dir)
      #     relative_path_to_primary_content_type: relative path from foreign to primary content_type, from config.setting('relative_path_to_primary_content_type')
      #     primary_repo_lang_code: primary repo's language_code_3_chars, from config.setting(:primary_repo_lang_code)
      # @return [String] the absolute path to the corresponding primary file
      def self.find(params)
        primary_content_type_base_dir = File.expand_path(
          params[:relative_path_to_primary_content_type],
          params[:content_type_dir]
        ) + '/'
        primary_filename = params[:filename].gsub(
          params[:content_type_dir],
          primary_content_type_base_dir
        ).gsub(
          /\/#{ params[:language_code_3_chars] }/,
          "/#{ params[:primary_repo_lang_code] }"
        )
      end

    end
  end
end
