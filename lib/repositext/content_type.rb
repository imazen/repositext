class Repositext

  # Represents a content_type in repositext
  # Has a name (e.g., 'general') which maps to it's directory (e.g., 'ct-general')
  class ContentType

    attr_accessor :base_dir

    delegate :base_dir,
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
             :primary_content_type_base_dir,
             :setting,
             to: :config,
             prefix: :config

    def self.new_from_config(config)
      ct = new('_')
      ct.config = config
      ct.base_dir = config.base_dir(:content_type)
      ct
    end

    # The name of the content type will be derived from the last segment of
    # base_dir.
    # Example: '/path/to/content_type/ct-general' will result in name 'general'
    # @param base_dir [String] absolute path to the root of the content type
    def initialize(base_dir, repository=nil)
      @base_dir = base_dir
      @repository = repository  if repository
    end

    # Lazily determines the containing git repo. Can also be set via initializer
    def repository
      @repository ||= Repository::Content.new(@base_dir)
    end

    def language
      @language ||= Repositext::Language.find_by_code(config_setting(:language_code_3_chars))
    end

    def name
      @name ||= @base_dir.split('/').last.sub(/\Act-/, '')
    end

    def config
      @config ||= (
        content_type_rtfile_path = File.join(
          @base_dir,
          'Rtfile'
        )
        Repositext::Cli::Config.new(content_type_rtfile_path).tap { |e| e.compute }
      )
    end
    def config=(a_config)
      @config = a_config
    end

    # @param content_type [String] the name of the content_type, e.g., 'general'
    def corresponding_primary_content_type
      self.class.new(corresponding_primary_content_type_base_dir)
    end

    def corresponding_primary_content_type_base_dir
      File.expand_path(
        config_setting(:relative_path_to_primary_content_type),
        config_base_dir(:content_type_dir)
      ) + '/'
    end

    def is_primary_repo
      config_setting(:is_primary_repo)
    end

  end
end
