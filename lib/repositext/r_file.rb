class Repositext

  # Represents an abstract RFile. Use concrete classes `Text` and `Binary`.
  class RFile

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

    # Returns the containing directory's complete path
    # @return [String]
    def dir
      File.dirname(filename)
    end

    def inspect
      [
        %(#<#{ self.class.name }:#{ object_id }),
        %(@contents=#{ is_binary ? '<binary>' : contents.truncate(50).inspect }),
        %(@filename=#{ filename.inspect }),
        %(@repository=#{ repository.inspect }),
      ].join(' ')
    end

    def is_binary
      raise "Implement #is_binary in subclass!"
    end

  end
end
