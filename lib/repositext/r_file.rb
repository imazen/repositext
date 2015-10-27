class Repositext
  class RFile

    # Represents a content file in repositext.

    include ContentSpecific
    # specificity boundary
    include ContentAtSpecific

    attr_reader :contents, :filename, :language, :repository

    delegate :corresponding_primary_repository,
             :is_primary_repo,
             :corresponding_primary_repo_base_dir,
             to: :repository,
             prefix: false

    # @param contents [String] the file's contents as string
    # @param language [Language] the file's language
    # @param filename [String] the file's absolute path
    # @param repository [Repositext::Repository, optional] the repository this file belongs to
    #     Required for certain operations. TODO: document here which ones.
    def initialize(contents, language, filename, repository=nil)
      raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
      raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
      raise ArgumentError.new("Invalid filename: #{ filename.inspect }")  unless filename.is_a?(String)
      raise ArgumentError.new("Invalid repository: #{ repository.inspect }")  unless (repository.nil? || repository.is_a?(Repository))
      @contents = contents
      @language = language
      @filename = filename
      @repository = repository
    end

    # Returns just the name without path
    def basename
      File.basename(filename)
    end

    def corresponding_primary_contents
      corresponding_primary_file.contents
    end

    def corresponding_primary_file
      return self  if is_primary_repo

      self.class.new(
        File.read(corresponding_primary_filename),
        corresponding_primary_repository.language,
        corresponding_primary_filename,
        corresponding_primary_repository
      )
    end

    def corresponding_primary_filename
      return filename  if is_primary_repo

      primary_filename = filename.sub(
        repository.config_base_dir(:rtfile_dir),
        corresponding_primary_repo_base_dir
      ).sub(
        /\/#{ repository.config_setting(:language_code_3_chars) }/,
        "/#{ repository.config_setting(:primary_repo_lang_code) }"
      )
    end

    # Returns the containing directory's complete path
    # @return [String]
    def dir
      File.dirname(filename)
    end

    def inspect
      %(#<#{ self.class.name }:#{ object_id } @contents=#{ contents.truncate(50).inspect } @filename=#{ filename.inspect } @repository=#{ repository.inspect })
    end

  end
end
