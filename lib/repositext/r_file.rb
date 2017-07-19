class Repositext

  # Represents an abstract RFile. Use concrete sub class instances!
  class RFile

    include HasGitVersioning

    attr_reader :content_type, :contents, :filename, :language

    # Optional content_type, without prefix
    delegate :corresponding_primary_content_type_base_dir,
             :corresponding_primary_content_type,
             :repository,
             to: :content_type,
             prefix: false,
             allow_nil: true
    # Requires content_type, with prefix
    delegate :base_dir, :config, :name, to: :content_type, prefix: true

    # Returns a relative path from source_path to target_path.
    # @param source_path [String] absolute path
    # @param target_path [String] absolute path
    # @return [String]
    def self.relative_path_from_to(source_path, target_path)
      source_pathname = Pathname.new(source_path)
      target_pathname = Pathname.new(target_path)
      target_pathname.relative_path_from(source_pathname).to_s
    end

    # Returns the class to use for RFiles based on filename's extension.
    # @param filename [String]
    # @return [Class]
    def self.get_class_for_filename(filename)
      # Go from most specific to most general
      case filename
      when /\.subtitle_markers\.csv\z/
        RFile::SubtitleMarkersCsv
      when /\.data\.json\z/
        RFile::DataJson
      when /\.docx\z/
        RFile::Docx
      when /\.pdf\z/
        RFile::Pdf
      when /\.at\z/
        RFile::ContentAt
      when /\.json\z/
        RFile::Json
      when /\-\d{4}.?_\d{4}\./
        # Date code followed by product identity id
        RFile::Content
      when /_\d\d_-_[a-z]+_\d{4}./
        # Sequence number followed by title and product identity id
        RFile::Content
      when /\.txt\z/
        RFile::Text
      else
        raise "Handle this: #{ filename.inspect }"
      end
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

    def inspect
      r = [
        %(#<#{ self.class.name }:#{ object_id }),
        %(@contents=#{ is_binary ? '<binary>' : contents.truncate(50).inspect }),
        %(@filename=#{ filename.inspect }),
        %(@repository=#{ repository.inspect }),
        %(@content_type=#{ content_type.inspect }),
      ]
      if is_git_versioned?
        r << %(@as_of_git_commit_attrs=#{ as_of_git_commit_attrs.inspect })
      end
      r.join(' ') + '>'
    end

    def is_binary
      false
    end

    def lang_code_3
      language.code_3_chars
    end

    # Lock self for a block so only one process can modify it at a time.
    # NOTE: This is from Rails' File Cache:
    # https://github.com/rails/rails/blob/932655a4ef61083da98724bb612d00f89e153c46/activesupport/lib/active_support/cache/file_store.rb#L103
    # OPTMIZE: We could use Rails Cache's File.atomic_write method for even better concurrency:
    # https://github.com/rails/rails/blob/932655a4ef61083da98724bb612d00f89e153c46/activesupport/lib/active_support/core_ext/file/atomic.rb
    def lock_self_exclusively(&block)
      if File.exist?(filename)
        File.open(filename, 'r+') do |f|
          begin
            f.flock File::LOCK_EX
            yield
          ensure
            f.flock File::LOCK_UN
          end
        end
      else
        yield
      end
    end

    # Reloads contents from filename
    def reload_contents!
      @contents = if is_binary
        File.binread(filename)
      else
        File.read(filename)
      end
    end

    # Returns relative path from repo root to self
    # @param include_repo_root [Boolean] if true, path will include the repo root dir
    # @return [String]
    def repo_relative_path(include_repo_root=false)
      leading_path_segments = if include_repo_root
        # Remove repo root dir from leading_path_segments to keep it
        Pathname.new(repository.base_dir).parent.to_s
      else
        repository.base_dir
      end
      # Remove leading path segments plus any leading slashes
      filename.sub(leading_path_segments, '').sub(/\A\//, '')
    end

    # Updates contents and persists them
    def update_contents!(new_contents)
      if is_binary
        File.binwrite(filename, new_contents)
      else
        File.write(filename, new_contents)
      end
    end

  end
end
