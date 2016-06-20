class Repositext
  class Subtitle

    # Represents all Subtitle::Operations resulting from a single git diff for
    # all files in a repository.
    #
    # Can be serialized to and from a JSON file
    #
    class OperationsForRepository

      ATTR_NAMES = [:fromGitCommit, :repository, :toGitCommit]

      attr_accessor :operations_for_files
      attr_accessor *ATTR_NAMES

      # Initializes self from operations serialized to JSON
      # @param json [String]
      # @param language [Repositext::Language]
      # @param repo_base_dir [String]
      def self.from_json(json, language, repo_base_dir)
        from_hash(JSON.parse(json, symbolize_names: true), language, repo_base_dir)
      end

      # Initializes self from operations persisted to file in `subtitle_operations` dir
      # @param hash [Hash] for repo
      # @param language [Repositext::Language]
      # @param repo_base_dir [String]
      def self.from_hash(hash, language, repo_base_dir)
        files = hash.delete(:files)
        new(
          hash,
          files.map { |file_attrs|
            file_path = File.join(repo_base_dir, file_attrs[:file_path])
            content_at_file = RFile::ContentAt.new(
              File.read(file_path),
              language,
              file_path
            )
            OperationsForFile.from_hash(content_at_file, file_attrs.merge(hash))
          }
        )
      end

      # @param attrs [Hash]
      #   {
      #     repository: 'english',
      #     fromGitCommit: '1234',
      #     toGitCommit: '2345',
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
      end

      # Call on self to invert `from` and `to` git commits as well as each
      # operation (i.e. a `merge` becomes a `split`, etc.)
      def invert!
        self.fromGitCommit, self.toGitCommit = [toGitCommit, fromGitCommit]
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

      # Replaces temp with persistent ids and adds them to stid inventory file
      # @param stids_inventory_file [IO]
      def replace_temp_with_persistent_ids!(stids_inventory_file)

      end

    end

  end
end
