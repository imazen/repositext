class Repositext

  # Represents an abstract RFile. Use concrete classes `Text` and `Binary`.
  class RFile

    attr_reader :contents, :filename, :language, :repository

    delegate :corresponding_primary_repo_base_dir,
             :corresponding_primary_repository,
             :is_primary_repo,
             to: :repository,
             prefix: false

    # Returns a relative path from source_path to target_path.
    # @param source_path [String] absolute path
    # @param target_path [String] absolute path
    # @return [String]
    def self.relative_path_from_to(source_path, target_path)
      source_pathname = Pathname.new(source_path)
      target_pathname = Pathname.new(target_path)
      target_pathname.relative_path_from(source_pathname).to_s
    end

    # Returns the class to use for RFiles. Either text or binary.
    # @param is_binary [Boolean]
    # @return [Class]
    def self.get_class_for_binary_or_not(is_binary)
      is_binary ? RFile::Binary : RFile::Text
    end

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

    # Returns self's date_code
    def extract_date_code
      basename.match(/\d{2}-\d{4}[[:alpha:]]?/).to_s
    end

    # Extracts a 4-digit product identity id from filename
    def extract_product_identity_id
      basename.match(/(?<=_)\d{4}(?=\.)/).to_s
    end

    # Extracts a 2-digit year from filename
    def extract_year
      extract_date_code.match(/\A\d{2}/).to_s
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

    def lang_code_3
      language.code_3_chars
    end

    def corresponding_content_at_contents
      corresponding_content_at_file.contents
    end

    def corresponding_content_at_file
      ccat_filename = corresponding_content_at_filename
      return nil  if !File.exists?(ccat_filename)
      RFile::Text.new(
        File.read(corresponding_content_at_filename),
        repository.language,
        ccat_filename,
        repository
      )
    end

    def corresponding_content_at_filename
      File.join(
        repository.config_base_dir(:rtfile_dir),
        'content',
        extract_year,
        [
          repository.config_setting(:language_code_3_chars),
          extract_date_code,
          '_',
          extract_product_identity_id,
          '.at'
        ].join
      )
    end

  end
end
