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
    delegate :name,
             to: :language,
             prefix: true

    # Returns an array with all available content_types for repo
    # @param repo [Repository]
    # @return [Array<ContentType>]
    def self.all(repo)
      all_names.map { |content_type_name|
        content_type_base_dir = File.join(
          repo.base_dir,
          "ct-#{ content_type_name }"
        )
        new(content_type_base_dir, repo)
      }
    end

    # Returns array of all available names
    def self.all_names
      %w[
        general
      ]
    end

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
      @base_dir = base_dir.sub(/\/?\z/, '/') # guaranteed to have trailing slash
      @repository = repository  if repository
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

    # Returns corresponding content_type in other repository.
    # @param other_repository [Repository]
    # @return [ContentType]
    def corresponding_content_type_in_other_repo(other_repository)
      return self  if other_repository.name == repository.name
      self.class.new(corresponding_content_type_base_dir_in_other_repo(other_repository))
    end

    # Returns base_dir to corresponding content_type in other_repository as
    # string with trailing slash.
    # @param other_repository [Repository]
    # @return [String]
    def corresponding_content_type_base_dir_in_other_repo(other_repository)
      base_dir.sub(repository.base_dir, other_repository.base_dir)
    end

    # Returns corresponding primary content_type.
    # @return [ContentType]
    def corresponding_primary_content_type
      return self  if is_primary_repo
      self.class.new(corresponding_primary_content_type_base_dir)
    end

    # Returns base_dir to corresponding primary content_type as string with
    # trailing slash.
    # @return [String]
    def corresponding_primary_content_type_base_dir
      # OPTIMIZE: Can we replace this method with #corresponding_content_type_base_dir_in_other_repo ?
      File.expand_path(
        config_setting(:relative_path_to_primary_content_type),
        config_base_dir(:content_type_dir)
      ) + '/'
    end

    def is_primary_repo
      config_setting(:is_primary_repo)
    end

    def language
      @language ||= Repositext::Language.find_by_code(config_setting(:language_code_3_chars))
    end

    def name
      @name ||= @base_dir.split('/').last.sub(/\Act-/, '')
    end

    # Lazily determines the containing git repo. Can also be set via initializer
    def repository
      @repository ||= Repository::Content.new(@base_dir)
    end

  end
end
