class Repositext
  class Repository

    # Represents a git content repository
    class Content < Repositext::Repository

      attr_reader :config

      delegate :add_base_dir,
               :add_file_extension,
               :add_file_selector,
               :add_kramdown_converter_method,
               :add_kramdown_parser,
               :add_setting,
               :base_dir,
               :compute_base_dir,
               :compute_file_extension,
               :compute_file_selector,
               :compute_glob_pattern,
               :compute_validation_file_specs,
               :file_extension,
               :file_selector,
               :get_config_val,
               :initialize,
               :kramdown_converter_method,
               :kramdown_parser,
               :primary_repo_base_dir,
               :setting,
               to: :config,
               prefix: :config

      # @param config [Repositext::Cli::Config] the repo's config object, based on Rtfile
      def initialize(config)
        raise ArgumentError.new("config is blank")  if config.blank?
        @config = config
        super(config_base_dir(:rtfile_dir))
      end


      def corresponding_primary_repository
        primary_rtfile_path = File.join(corresponding_primary_repo_base_dir, 'Rtfile')
        primary_config = Repositext::Cli::Config.new(primary_rtfile_path)
        primary_config.eval
        self.class.new(primary_config)
      end

      def corresponding_primary_repo_base_dir
        File.expand_path(
          config_setting(:relative_path_to_primary_repo),
          config_base_dir(:rtfile_dir)
        ) + '/'
      end

      def is_primary_repo
        config_setting(:is_primary_repo)
      end

      def language
        Repositext::Language.find_by_code(config_setting(:language_code_3_chars))
      end

    end
  end
end
