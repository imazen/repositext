class Repositext

  # Represents an abstract RFile. Use concrete sub class instances!
  class RFile

    attr_reader :content_type, :contents, :filename, :language

    delegate :corresponding_primary_content_type_base_dir,
             :corresponding_primary_content_type,
             :repository,
             to: :content_type,
             prefix: false,
             allow_nil: true

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

    # Returns copy of self with contents as of a commit relative to git_commit_sha1.
    # reference can be one of:
    #   * :at_commit - as of the commit.
    #   * :at_next_commit - as of next commit that included self, or current
    #     contents if there is no next commit.
    # @param git_commit_sha1 [String]
    # @return [RFile]
    def as_of_git_commit(git_commit_sha1, reference=:at_commit)
      if !git_commit_sha1.is_a?(String)
        raise ArgumentError.new("Invalid git_commit_sha1: #{ git_commit_sha1.inspect }")
      end
      if '' == git_commit_sha1.to_s
        raise ArgumentError.new("Invalid git_commit_sha1: #{ git_commit_sha1.inspect }")
      end
      # Instantiate copy of self with contents as of the requested version
      new_contents = case reference
      when :at_commit
        # Use git_commit_sha1
        `git --no-pager show #{ git_commit_sha1 }:#{ repo_relative_path }`
      when :at_next_commit
        # Find next commit's sha1
        # Get all commits between git_commit_sha1 and HEAD in reverse order,
        # starting with the next one after git_commit_sha1, ending with HEAD,
        # one commit sha1 per line.
        all_commit_sha1s, _ = Open3.capture2(
          [
            "git",
            "--git-dir=#{ repository.repo_path }",
            "log",
            "--reverse",
            "--pretty=format:'%H'",
            "--ancestry-path",
            "#{git_commit_sha1}..HEAD",
            "--",
            filename.sub(repository.base_dir, ''),
          ].join(' ')
        )
        next_commit_sha1 = all_commit_sha1s.lines.first
        if '' != next_commit_sha1.to_s
          # Load contents as of next commit
          `git --no-pager show #{ next_commit_sha1 }:#{ repo_relative_path }`
        else
          # No next commit, use current file contents
          is_binary ? File.binread(filename) : File.read(filename)
        end
      else
        raise "Handle this: #{ reference.inspect }"
      end
      # Return new instance of self
      self.class.new(new_contents, language, filename, content_type)
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
        %(@content_type=#{ content_type.inspect }),
      ].join(' ')
    end

    def is_binary
      false
    end

    def lang_code_3
      language.code_3_chars
    end

    # Returns the latest git commit that included self. Before_time is optional
    # and defaults to now.
    # @param before_time [Time, optional]
    # @return [Rugged::Commit]
    def latest_git_commit(before_time=nil)
      return nil  if repository.nil?
      repository.latest_commit(filename, before_time)
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
      @contents = File.read(filename)
    end

    # Returns relative path from repo root to self
    def repo_relative_path
      filename.sub(repository.base_dir, '')
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
