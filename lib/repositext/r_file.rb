class Repositext

  # Represents an abstract RFile. Use concrete classes `Text` and `Binary`.
  class RFile

    attr_reader :content_type, :contents, :filename, :language

    delegate :corresponding_primary_content_type_base_dir,
             :corresponding_primary_content_type,
             :is_primary_content_type,
             :repository,
             to: :content_type,
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
    # @param content_type [Repositext::ContentType, optional] the content_type
    #     this file belongs to. Required for certain operations.
    #     TODO: document here which ones.
    def initialize(contents, language, filename, content_type=nil)
      raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
      raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
      raise ArgumentError.new("Invalid filename: #{ filename.inspect }")  unless filename.is_a?(String)
      raise ArgumentError.new("Invalid content_type: #{ content_type.inspect }")  unless (content_type.nil? || content_type.is_a?(ContentType))
      @contents = contents
      @language = language
      @filename = filename
      @content_type = content_type
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
        %(@content_type=#{ content_type.inspect }),
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
        content_type.language,
        ccat_filename,
        content_type
      )
    end

    def corresponding_content_at_filename
      File.join(
        content_type.base_dir,
        'content',
        extract_year,
        [
          content_type.config_setting(:language_code_3_chars),
          extract_date_code,
          '_',
          extract_product_identity_id,
          '.at'
        ].join
      )
    end

  end
end
