class Repositext
  class Subtitle

    # Represents all Subtitle::Operations resulting from a single git diff for
    # all files in a repository.
    #
    # Can be serialized to and from a JSON file
    class OperationsForRepository

      ATTR_NAMES = [
        :first_operation_id,
        :from_git_commit,
        :last_operation_id,
        :repository,
        :to_git_commit,
      ]

      attr_accessor :operations_for_files
      attr_accessor *ATTR_NAMES

      # Initializes self from operations serialized to JSON
      # @param json [String]
      # @param repo_base_dir [String]
      def self.from_json(json, repo_base_dir)
        from_hash(JSON.parse(json, symbolize_names: true), repo_base_dir)
      end

      # Initializes self from operations persisted to file in `subtitle_operations` dir
      # @param hash [Hash] for repo
      # @param repo_base_dir [String]
      def self.from_hash(hash, repo_base_dir)
        files = hash.delete(:files)
        new(
          hash,
          files.map { |file_attrs|
            file_path = File.join(repo_base_dir, file_attrs[:file_path])
            repository = Repository.new(repo_base_dir)
            content_type_base_dir = File.join(
              repo_base_dir, file_attrs[:file_path].split('/').first
            )
            content_type = ContentType.new(
              content_type_base_dir,
              repository
            )
            content_at_file = RFile::ContentAt.new(
              File.read(file_path),
              content_type.language,
              file_path,
              content_type
            )
            OperationsForFile.from_hash(content_at_file, file_attrs.merge(hash))
          }
        )
      end

      # @param attrs [Hash]
      #   {
      #     repository: 'english',
      #     from_git_commit: '1234',
      #     to_git_commit: '2345',
      #     first_operation_id: 123,
      #     last_operation_id: 456,
      #   }
      # @param operations_for_files [Array<Repositext::Subtitle::OperationsForFile>]
      def initialize(attrs, operations_for_files)
        if (off = operations_for_files.first) && !off.is_a?(Repositext::Subtitle::OperationsForFile)
          raise ArgumentError.new("Invalid first operations_for_file: #{ off.inspect }")
        end
        ATTR_NAMES.each do |attr_name|
          self.send("#{ attr_name }=", attrs[attr_name])
        end
        self.operations_for_files = operations_for_files
        if !(
          @first_operation_id.to_i < @last_operation_id.to_i
        )
          raise ArgumentError.new("Invalid operation_id boundaries: #{ [@first_operation_id, @last_operation_id].inspect }")
        end
      end

      # Returns array of all content AT files with ops
      # @return [Array<RFile::ContentAt>]
      def affected_content_at_files
        operations_for_files.map { |e| e.content_at_file }
      end

      # Returns operations for file with product_identity_id, or nil if none
      # exist.
      # @param product_identity_id [String]
      # @return [Subtitle::OperationsForFile, Nil]
      def get_operations_for_file(product_identity_id)
        operations_for_files.detect { |e|
          e.content_at_file.extract_product_identity_id == product_identity_id
        }
      end

      # Call on self to invert `from` and `to` git commits as well as each
      # operation (i.e. a `merge` becomes a `split`, etc.)
      def invert!
        self.from_git_commit, self.to_git_commit = [to_git_commit, from_git_commit]
        self.operations_for_files = operations_for_files.map { |e| e.invert!; e }
      end

      # Converts self to Hash
      # @return [Hash]
      def to_hash
        r = ATTR_NAMES.inject({}) { |m,e|
          m[e] = self.send(e)
          m
        }
        r[:files] = operations_for_files.map { |e| e.to_hash }
        r
      end

      # Serializes self to json
      # @return [String]
      def to_json
        #JSON.fast_generate(to_hash)
        JSON.pretty_generate(to_hash)
      end

    end

  end
end
